// SetFileTime.c
// Set Creation, Access, or Write time of a file
// On NTFS file systems, creation, access and write time are stored for each
// file. SetFileTime can set these times for writable files.
//
// SetFileTime(FileName, TimeSpec, Time, Type)
// INPUT:
//   FileName: String, file or folder name with or without absolute or relative
//             path.
//   TimeSpec: String specifying the time, which should be touched. Just the
//             first character matters.
//             'Creation': Time of creation,
//             'Access':   Time of last access,
//             'Write':    Time of last modification.
//   Time:     Current local time as [1 x 6] double vectorin DATEVEC format,
//             e.g. as replied from CLOCK. Milliseconds are considered.
//             The time is converted to UTC.
//   Type:     String, type of the conversion from local time to UTC file time.
//             Optional, default: "Local". Just the 1st character matters.
//             "Local": The file time is converted from the local time
//                      considering the daylight saving setting of the specific
//                      time.
//             "Windows": The time conversion considers the current daylight
//                      saving time as usual for Windows (e.g. the Windows
//                      Explorer). If the daylight saving changes, the file
//                      times can change also.
//             "UTC":   The input is written as UTC time without a conversion.
//
// The function stops with an error if:
//   - the file does not exist or cannot be opened in write mode,
//   - the time conversions fail,
//   - the number or type of inputs/outputs is wrong.
//
// EXAMPLE:
//   File = tempname;
//   D = dir(File)
//   SetFileTime(File, 'Write', [2009, 24, 12, 16, 32, 29]);
//   D = dir(File)
//
// NOTES:
// - The function is tested for NTFS drives only. It seems that it could work on
//   FAT file systems also.
// - The "Windows" method adjusts the times according to the currently active
//   DST. Therefore a "changed" time stamp does not necessarily mean, that the
//   file is changed, but eventuall only the daylight saving time.
//   Although this might be confusing, it is a valid method to handle the hours
//   during the DST switches consistently.
// - With the "Local" conversion, the times during the DST switches cannot be
//   converted consistently, e.g. 2009-Mar-08 02:30:00 (does not exist) and
//   2009-Nov-01 02:30:00 (exists twice). But for the half of the other 8758
//   hours of the year, "Local" is more consistent than the "Windows"
//   conversion.
// - Matlab's DIR command showed the "Windows" write time until 6.5.1 and the
//   "Local" value for higher versions.
// - This function works under WindowsXP or Windows Server 2003 and higher only,
//   because the API function TzSpecificLocalTimeToSystemTime is called.
//   The header files <windows.h> of LCC2.4 (shipped with Matlab up to 2009a and
//   higher?!) and BCC5.5 does not contain the prototype of this function. The
//   free compilers LCC 3.8 and OpenWatcom 1.8 can compile SetFileTime.
// - Unix/OSX not supported yet.
// - Run the function TestFileTime after compiling the MEX files. I recommend to
//   move TestFileTime to a folder where it does not bother.
//
// Compilation of MEX source (after "mex -setup" on demand):
//   mex -O SetFileTime.c
// Precompiled MEX files can be found at: http://www.n-simon.de/mex
//
// Tested: Matlab 6.5, 7.7, LCC3.8, OpenWatcom1.8, WinXP, [UnitTest]
// Author: Jan Simon, Heidelberg, (C) 2009 matlab.2009ATnMINUSsimonDOTde
//
// See also: DIR, CLOCK, DATEVEC, DATESTR.

/*
% $JRev: R0o V:014 Sum:5C05CE9F Date:20-Nov-2009 10:29:54 $
% $File: User\JSim\Published\FileTime\SetFileTime.c $
% History:
% 001: 21-Aug-2007 00:37, Initial version.
% 008: 09-Jul-2009 00:35, Input TimeSpec: 'Modification' -> 'Write'.
% 011: 10-Nov-2009 11:01, UTC->Local/Windows/UTC conversion.
% 012: 15-Nov-2009 00:43, Works with directories also now.
*/

#if defined(WIN32) || defined(_WIN32)
#include <windows.h>
#else
#error Implemented for Windows only now!
#endif

#include "mex.h"
#include <math.h>

// Enumerator for types of time conversion:
static enum ConversionType {WIN_TIME, LOCAL_TIME, UTC_TIME};

// Prototypes:
void DropError(const char *ErrorID, const char *Msg, HANDLE *H);

// Main function ===============================================================
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  unsigned char *FileName, TimeSpec, TypeIn;
  double     *Time, Second;
  HANDLE     *H;
  FILETIME   localT, utcT;
  SYSTEMTIME ST, ST2;
  BOOL       Success;
  
  // Default: Use conversion with DST at the specified date and time:
  enum ConversionType Type = LOCAL_TIME;
  
  // Get 4th input, if it is used:
  if (nrhs == 4) {
    // Check type of 4th input:
    if (!mxIsChar(prhs[3]) || mxGetNumberOfElements(prhs[3]) == 0) {
      mexErrMsgIdAndTxt("JSim:SetFileTime:BadType",
                        "SetFileTime: 4th input [Type] must be a string.");
    }
    
    // "W" for "Windows", "U" for "UTC", "L" for real local time (default):
    TypeIn = (char) tolower(*(char *)mxGetData(prhs[3]));
    if (TypeIn == 'w') {         // As Windows: Adjust to current DST
      Type = WIN_TIME;
    } else if (TypeIn == 'u') {  // UTC time: Not affected by DST
      Type = UTC_TIME;
    }
  } else if (nrhs != 3) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:BadNArgin",
                      "SetFileTime: 3 or 4 inputs required.");
  }
  
  // Limit number of outputs:
  if (nlhs > 1) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:BadNArgout",
                      "SetFileTime: 1 output allowed.");
  }
  
  // Type of input arguments:
  if (!mxIsChar(prhs[0])) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:BadFileName",
                      "SetFileTime: 1st input must be the file name.");
  }
  if (!mxIsChar(prhs[1]) || mxIsEmpty(prhs[0])) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:BadTimeSpec",
                      "SetFileTime: 2nd input must be time specifier.");
  }
  if (!mxIsDouble(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 6) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:BadDateVector",
                      "SetFileTime: 3rd input must be a date vector.");
  }
  
  // Get the file name:
  if ((FileName = mxArrayToString(prhs[0])) == NULL) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:BadFileNameConversion",
                      "SetFileTime: FileName to C-string failed.");
  }
  
  // Get a file handle:
  // Call DropError afterwards in case of errors to close the handle!
  H = CreateFile(
        (LPCTSTR) FileName,         // pointer to name of the file
        GENERIC_WRITE,              // access (read-write) mode
        FILE_SHARE_READ, NULL,      // share mode and security
        OPEN_EXISTING,              // do not create
        FILE_FLAG_BACKUP_SEMANTICS, // attributes
        NULL);                      // attribute template handle
  
  mxFree(FileName);                 // Release as soon as possible
  
  if (H == INVALID_HANDLE_VALUE) {
     DropError("JSim:SetFileTime:MissingFile",
               "SetFileTime: File is not existing or a folder.", H);
  }
  
  // Get time specificator and time:
  TimeSpec = (char) tolower(*(char *) mxGetData(prhs[1]));
  Time     = mxGetPr(prhs[2]);
  
  // Create system time struct containing local time:
  // Special rounding for milliseconds, split seconds as integer part:
  ST.wMilliseconds = (int) (modf(Time[5], &Second) * 1000 + 0.5);
  ST.wYear   = (int) Time[0];
  ST.wMonth  = (int) Time[1];
  ST.wDay    = (int) Time[2];
  ST.wHour   = (int) Time[3];
  ST.wMinute = (int) Time[4];
  ST.wSecond = (int) Second;   // AFTER wMilliseconds due to modf call !!!
  
  // Convert input date to UTC with different methods:
  switch (Type) {
    case LOCAL_TIME:
      // Convert UTC FILETIME to system time:
      if (TzSpecificLocalTimeToSystemTime(NULL, &ST, &ST2) == 0) {
        DropError("JSim:SetFileTime:BadLocal_UTC2SysTime",
                  "SetFileTime: Specific SYSTEMTIME to UTC failed.", H);
      }
      
      // UTC system time to UTC file time:
      if (SystemTimeToFileTime(&ST2, &utcT) == 0) {
        DropError("JSim:SetFileTime:BadLocal_Sys2FileTime",
                  "SetFileTime: Time to FILETIME failed!", H);
      }
      break;
      
    case WIN_TIME:
      // System to FILETIME:
      if (SystemTimeToFileTime(&ST, &localT) == 0) {
        DropError("JSim:SetFileTime:BadWin_Sys2FileTime",
                  "SetFileTime: Time to FILETIME failed!", H);
      }
      
      // Local time to UTC with current DST value:
      if (LocalFileTimeToFileTime(&localT, &utcT) == 0) {
        DropError("JSim:SetFileTime:BadWin_Local2UTC",
                  "SetFileTime: Local to UTC FILETIME failed!", H);
      }
      break;
      
    case UTC_TIME:
      // System to FILETIME, input is UTC already:
      if (SystemTimeToFileTime(&ST, &utcT) == 0) {
        DropError("JSim:SetFileTime:BadUTC_Sys2FileTime",
                  "SetFileTime: Time to FILETIME failed!", H);
      }
      break;
      
    default:
      DropError("JSim:SetFileTime:BadTypeSwitch",
                "SetFileTime: Programming error!", H);
  }
  
  // Creation, last Access, last Write:
  if (TimeSpec == 'c') {
    Success = SetFileTime(H, &utcT, NULL, NULL);
  } else if (TimeSpec == 'a') {
    Success = SetFileTime(H, NULL, &utcT, NULL);
  } else if (TimeSpec == 'w') {
    Success = SetFileTime(H, NULL, NULL, &utcT);
  } else {
    DropError("JSim:SetFileTime:BadTimeSpec", "SetFileTime: Bad TimeSpec!", H);
  }
  
  // Close the file before checking success:
  CloseHandle(H);

  if (Success == 0) {
    mexErrMsgIdAndTxt("JSim:SetFileTime:SetTimeFailed",
                      "SetFileTime: WindowsAPI:SetFileTime failed!");
  }
    
  return;
}

// =============================================================================
void DropError(const char *ErrorID, const char *Msg, HANDLE *H)
{
  // Close handle before stopping with an error:
  CloseHandle(H);
  mexErrMsgIdAndTxt(ErrorID, Msg);
}
