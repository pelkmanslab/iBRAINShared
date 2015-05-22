function handles = getframesformovie(handles,matOrderedTimePointIdx,strSettingBaseName)

%[VZ]: Makes the function more general. In ObjRow = Row for current
%objId, ParRow= row for previousObjID, FamRow = for familyID


%%% Load settings etc.
cellAllSegmentedImages = handles.Measurements.Image.SegmentedFileNames';
cellAllTrackedImages = handles.Measurements.Image.TrackedFileNames';
SetBeingAnalyzed = 1;
ObjectName = handles.TrackingSettings.ObjectName;
TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
numTail = handles.TrackingSettings.TailTime;

%[VZ]: Makes the function more flexible:

%Use Global Labels whenever possible:
NameSeq = handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'Features'))(:);
ObjRow=strcmp(NameSeq,'GlobalObjectID');
ParRow=strcmp(NameSeq,'GlobalParentID');
FamRow=strcmp(NameSeq,'GlobalFamilyID');

ObjRow= find(ObjRow);
ParRow= find(ParRow);
FamRow= find(FamRow);

if isempty(FamRow)
ObjRow=strcmp(NameSeq,'ObjectID');
ParRow=strcmp(NameSeq,'ParentID');
FamRow=strcmp(NameSeq,'FamilyID');

ObjRow= find(ObjRow);
ParRow= find(ParRow);
FamRow= find(FamRow);
fprintf('No global labels present, use local labels for movie creation')

else
 fprintf('Use global labels for movie creation')   
end


%%% Initiate colour maps
matColorMap = hsv(1500)+0.2;
matColorMap(matColorMap>1) = 1;
matColorMapTail = matColorMap-0.3;
matColorMapTail(matColorMapTail<0) = 0;
[~,n1] = unique(matColorMap,'rows');
[~,n2] = unique(matColorMapTail,'rows');
matColorMap = matColorMap(intersect(n1,n2),:);
matColorMapTail = matColorMapTail(intersect(n1,n2),:);



%%% Now initialize the colour indices vector, where each row corresponds to a
%%% to a familyID.


%make the random stuff reproducible
%rng(12343);
%MatFamilytoColour is a random sequence corresponding to randperm(1056)'
matFamilytoColour = [441;382;620;934;511;741;332;899;155;1007;283;281;714;846;704;717;603;59;972;452;53;632;924;94;125;551;831;996;749;250;15;740;457;869;678;768;590;742;669;733;212;404;568;341;918;29;476;515;607;428;548;57;34;896;495;70;892;372;346;600;659;726;975;995;394;917;156;238;432;778;140;385;118;313;730;1049;534;988;215;83;909;221;689;8;967;369;254;353;1013;788;688;661;791;183;866;945;549;541;1009;307;927;564;320;429;181;514;654;418;112;716;814;277;132;968;552;781;103;987;992;1008;997;923;1056;811;1029;461;635;407;981;384;931;720;868;151;415;581;1031;954;496;84;383;715;209;510;642;627;205;509;691;936;185;305;576;594;269;479;701;886;651;890;276;333;835;179;696;1021;519;360;163;210;66;211;529;928;849;812;445;505;647;310;58;640;42;588;506;242;401;825;864;666;526;468;984;75;172;820;668;851;326;13;656;157;853;512;794;693;17;78;73;670;518;317;80;408;450;494;37;20;387;197;2;362;516;95;167;352;115;785;331;1054;823;639;626;203;1032;39;351;861;582;4;567;817;26;191;166;229;134;105;287;711;206;676;732;109;520;765;752;169;706;961;252;889;484;597;844;827;925;477;304;164;877;786;442;300;562;1019;303;709;767;398;448;430;919;1041;222;316;694;188;595;240;555;815;411;123;799;47;110;836;734;139;251;535;200;367;953;32;645;865;344;641;237;162;390;7;343;773;935;1037;685;56;1048;609;862;803;719;9;828;481;460;504;818;617;111;236;150;393;637;916;245;850;542;879;776;540;315;1051;847;133;366;499;500;713;278;513;660;87;986;813;795;839;871;550;705;842;722;663;665;888;622;905;124;565;116;379;1043;908;929;128;223;113;959;455;672;955;938;288;586;82;570;93;409;985;878;395;974;204;750;884;933;830;606;1020;337;201;286;321;702;375;424;88;145;463;840;1023;273;699;624;138;574;328;108;60;402;52;718;388;939;18;312;944;677;272;196;260;147;397;537;322;186;793;751;998;1044;373;977;903;1030;662;244;845;532;280;279;21;490;216;539;492;86;371;64;755;127;92;822;557;545;680;873;797;370;130;601;572;621;386;381;81;739;400;584;44;465;207;900;880;507;233;189;323;625;31;19;652;90;798;97;194;872;774;50;764;100;700;524;569;1015;782;848;101;487;232;1018;560;857;182;431;422;190;503;746;807;658;99;414;290;769;1024;271;299;789;579;648;228;745;72;282;25;802;192;644;863;309;361;302;692;41;808;426;325;623;523;243;43;766;946;451;149;231;629;170;695;230;687;1016;592;964;122;914;449;686;834;40;1055;502;22;141;224;54;347;897;991;275;10;49;36;932;556;285;952;336;421;359;464;993;46;311;754;160;543;885;578;810;697;1002;915;444;136;356;24;667;728;962;358;759;498;350;459;471;27;902;420;301;354;538;378;126;673;508;493;787;775;536;220;1045;98;753;187;342;978;969;474;174;618;345;131;153;824;417;744;158;253;947;217;671;458;638;770;841;419;816;708;165;1012;436;225;748;893;777;615;154;553;142;883;74;630;843;291;922;727;462;469;446;783;6;920;137;1038;937;319;96;707;438;970;433;195;605;114;478;1000;268;610;653;255;833;926;1005;298;1028;721;757;318;882;800;89;33;473;296;161;906;983;1046;68;577;675;405;951;45;870;602;297;921;348;725;11;950;559;636;837;1026;267;854;780;522;1039;486;488;1017;616;683;324;763;771;521;684;664;858;655;262;65;340;363;573;613;380;634;891;563;737;293;575;389;960;274;525;528;79;976;265;895;412;1025;144;674;723;958;180;852;416;943;472;657;3;63;482;612;1022;876;264;485;61;829;294;176;930;177;805;731;365;55;226;338;152;989;374;980;628;258;349;435;107;327;148;901;571;826;456;178;729;121;756;585;219;306;413;561;453;948;129;292;263;904;208;1001;712;544;284;875;1014;809;71;736;913;391;587;649;28;724;608;475;466;368;396;247;591;738;910;819;334;554;35;860;838;881;531;184;443;406;546;77;1042;887;241;168;832;547;289;1047;497;859;611;248;308;821;965;631;1003;76;855;589;440;91;234;335;940;51;614;703;171;796;102;23;784;146;566;643;911;517;175;762;202;213;483;1006;583;376;1053;355;489;894;434;1027;790;295;427;364;410;599;994;806;735;12;467;979;949;698;106;1033;425;30;792;119;760;747;593;314;1011;249;1004;5;501;598;761;214;604;62;779;330;199;982;804;679;527;104;16;907;392;437;454;856;1040;867;966;491;120;1;67;956;1052;85;173;470;399;193;1050;135;758;801;159;218;447;990;957;941;227;38;143;999;874;14;377;246;117;257;259;912;256;235;973;580;1035;646;423;339;690;530;239;266;681;682;357;942;439;48;329;480;1010;1036;403;650;710;270;261;963;1034;198;898;69;533;772;743;971;558;619;633;596];


for i =  1:size(matOrderedTimePointIdx,1)    %NumberOfImageSets
    
    % Load the current image, location and objects
    matCurrentImage = single(imread(char(cellAllSegmentedImages(matOrderedTimePointIdx(i)))));
    cellTrackLocations{1} = round(handles.Measurements.(ObjectName).Location{matOrderedTimePointIdx(i)});
    cellTrackObjectFamilyIDs{1} = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){matOrderedTimePointIdx(i)}(:,FamRow);
    
    matCurrentFamilyIDs = cellTrackObjectFamilyIDs{1};
    
    % Check if the current matFamilytoColour Vector is long enough, else
    % extend it
    
    while max(matCurrentFamilyIDs) > size(matFamilytoColour,1)
        
        matFamilytoColour = [matFamilytoColour; matFamilytoColour];

    end
    
    %%% Convert the currentFamilyID vector to a colour vector
    
    matCurrentColours = matFamilytoColour(matCurrentFamilyIDs);
    
    %Generate the image with the diamonds
     if numTail > 0
        matCentroidIndx = cell2mat(arrayfun(@(x,y) sub2ind(size(matCurrentImage),x,y),...
            cellTrackLocations{1}(:,2),cellTrackLocations{1}(:,1),'uniformoutput',false));
        matDiamondImageIdx = zeros(size(matCurrentImage));
        matDiamondImageIdx(matCentroidIndx) = matCurrentColours;
        sel = strel('diamond',4);
        matDiamondImageIdx = imdilate(matDiamondImageIdx,sel); clear sel;
     end
    
    
    %Colour the segmentation correctly
    matNucleiImageIdx = zeros(size(matCurrentImage));
    matNucleiImageIdx(matCurrentImage>0) = matCurrentColours(matCurrentImage(matCurrentImage>0));


    % colour the border slightly different
    se = strel('disk',2,0);
    matBorderImageIdx = imdilate(edge_bs(matNucleiImageIdx),se) .* imdilate(matNucleiImageIdx,se);
    % figure;imagesc(matBorderImageIdx)
    
    
      if i == 1 && numTail > 0
        for iCell = 1:numTail
            cellRemDiamImIdx{iCell} = matDiamondImageIdx;
        end
    end
    
    matCurrentImage_1 = zeros(size(matCurrentImage));
    matCurrentImage_2 = zeros(size(matCurrentImage));
    matCurrentImage_3 = zeros(size(matCurrentImage));
    
    matCurrentImage_1( matNucleiImageIdx> 0) = matColorMap(  matNucleiImageIdx( matNucleiImageIdx> 0),1);
    matCurrentImage_2( matNucleiImageIdx> 0) = matColorMap(  matNucleiImageIdx( matNucleiImageIdx> 0),2);
    matCurrentImage_3( matNucleiImageIdx> 0) = matColorMap(  matNucleiImageIdx( matNucleiImageIdx> 0),3);
    
    matCurrentImage_1( matBorderImageIdx> 0) = matColorMapTail(  matBorderImageIdx( matBorderImageIdx> 0),1);
    matCurrentImage_2( matBorderImageIdx> 0) = matColorMapTail(  matBorderImageIdx( matBorderImageIdx> 0),2);
    matCurrentImage_3( matBorderImageIdx> 0) = matColorMapTail(  matBorderImageIdx( matBorderImageIdx> 0),3);
    
    
    if numTail > 0
        cellRemDiamImIdx{1} = matDiamondImageIdx;
        for iTime = 1:length(cellRemDiamImIdx)
            matCurrentImage_1(cellRemDiamImIdx{iTime} > 0) = matColorMapTail(cellRemDiamImIdx{iTime}(cellRemDiamImIdx{iTime} > 0),1);
            matCurrentImage_2(cellRemDiamImIdx{iTime} > 0) = matColorMapTail(cellRemDiamImIdx{iTime}(cellRemDiamImIdx{iTime} > 0),2);
            matCurrentImage_3(cellRemDiamImIdx{iTime} > 0) = matColorMapTail(cellRemDiamImIdx{iTime}(cellRemDiamImIdx{iTime} > 0),3);
        end
    end
    
    
    
    
    clear finalImage
    finalImage(:,:,1) = matCurrentImage_1;
    finalImage(:,:,2) = matCurrentImage_2;
    finalImage(:,:,3) = matCurrentImage_3;
    
    % figure;imshow(finalImage)
    
    finalImage = imresize(finalImage, [NaN 800]);
    imwrite(finalImage,cellAllTrackedImages{matOrderedTimePointIdx(i)},'png');
    %imwrite(finalImage,strcat('Z:\Data\Users\mRNAmes\Code\Movies\TEST\',num2str(i),'.png'),'png');
    
    if numTail > 0
    for iCell = length(cellRemDiamImIdx):-1:2
        cellRemDiamImIdx{iCell} = cellRemDiamImIdx{iCell-1};
    end
    end
    
end

    
