#!/bin/sh
#
# Bootstraps the buildDocumentation.m matlab script
#
# Expects to be run from the top-level folder of iBRAINShared
#
#
filepath='./Scripts/buildDocumentation.m'
matlab -nodesktop -nosplash -nodisplay -r "cd('..'); m2html('mfiles','iBRAINShared','recursive','on','htmlDir','docMatlab') ; quit;" 


