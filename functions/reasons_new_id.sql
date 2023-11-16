-->REASONS_NEW_ID|ddl
CREATE OR REPLACE FUNCTION REASONS_NEW_ID(old_id NUMBER) RETURN NUMBER IS
    l_result NUMBER;
BEGIN
    SELECT CASE
                WHEN old_id IS NULL THEN 
                 NULL
                WHEN old_id IN (702000010015) THEN
                 2869            
                WHEN old_id IN (702000010015) THEN
                 2869
                WHEN old_id IN (257) THEN
                 2874
                WHEN old_id IN (254) THEN
                 2875
                WHEN old_id IN (255) THEN
                 2876
                WHEN old_id IN (702000010014) THEN
                 2882
                WHEN old_id IN (1177, 1180, 1229, 1230, 1248, 1249, 1272, 1273, 1296, 1297) THEN
                 2884
                WHEN old_id IN (200) THEN
                 2890
                WHEN old_id IN (201) THEN
                 2891
                WHEN old_id IN (280) THEN
                 2895
                WHEN old_id IN (279, 283) THEN
                 2896
                WHEN old_id IN (21, 282) THEN
                 2897
            
                WHEN old_id IN (1268, 1269, 1292, 1293) THEN
                 2900
            
                WHEN old_id IN (1513) THEN
                 2908
            
                WHEN old_id IN (1512) THEN
                 2910
            
                WHEN old_id IN (3,
                                5,
                                7,
                                9,
                                11,
                                13,
                                27,
                                29,
                                31,
                                38,
                                39,
                                41,
                                44,
                                53,
                                58,
                                61,
                                63,
                                65,
                                98,
                                102,
                                104,
                                135,
                                138,
                                143,
                                147,
                                151,
                                156,
                                161,
                                203,
                                205,
                                207,
                                208,
                                209,
                                210,
                                218,
                                224,
                                226,
                                250,
                                252,
                                350,
                                360,
                                400,
                                1090,
                                1094,
                                1100,
                                1107,
                                1111,
                                1117,
                                1176,
                                1179,
                                1351,
                                1423,
                                1511,
                                1518,
                                10005,
                                10013,
                                10015,
                                10023,
                                10065,
                                10500,
                                999000010000,
                                999000010006,
                                1545,
                                1540,
                                1535,
                                1530
                                ) THEN
                 2911
            
                WHEN old_id IN (85, 1170, 1432, 702000010010) THEN
                 2912
            
                WHEN old_id IN (256) THEN
                 2913
            
                WHEN old_id IN (1,
                                16,
                                35,
                                52,
                                134,
                                216,
                                302,
                                304,
                                306,
                                308,
                                310,
                                1427,
                                1494,
                                10021,
                                10026,
                                10028,
                                10050,
                                10053,
                                10061,
                                10067,
                                702000010000,
                                702000010030,
                                702000010031,
                                702000010032,
                                702000010033,
                                702000010034) THEN
                 2914
            
                WHEN old_id IN (82) THEN
                 2915
            
                WHEN old_id IN (34) THEN
                 2916
            
                WHEN old_id IN (84) THEN
                 2917
            
                WHEN old_id IN (1096, 1113) THEN
                 2918
            
                WHEN old_id IN (1095, 1112) THEN
                 2919
            
                WHEN old_id IN (1514) THEN
                 2920
            
                WHEN old_id IN (1227, 1228, 1246, 1247, 1267, 1270, 1271, 1291, 1294, 1295) THEN
                 2922
            
                WHEN old_id IN (125, 126, 1251, 1275, 5006, 5007) THEN
                 2924
            
                WHEN old_id IN (87, 702000010011) THEN
                 2930
            
                WHEN old_id IN (284) THEN
                 2938
            
                WHEN old_id IN (1174) THEN
                 2939
            
                WHEN old_id IN (22, 129, 285, 1435, 5010) THEN
                 2940
            
                WHEN old_id IN (702000010002, 999000010002) THEN
                 2941
            
                WHEN old_id IN (59,
                                68,
                                79,
                                127,
                                128,
                                141,
                                145,
                                149,
                                154,
                                158,
                                1101,
                                1118,
                                1354,
                                1424,
                                1495,
                                5008,
                                5009,
                                10056,
                                10063,
                                10069,
                                10075,
                                10079,
                                999000010009,
                                999000010022,
                                1541,
                                1531
                                ) THEN
                 2944
            
                WHEN old_id IN (10018) THEN
                 2945
            
                WHEN old_id IN (17, 1374) THEN
                 2946
            
                WHEN old_id IN (19, 23) THEN
                 2948
            
                WHEN old_id IN (10105) THEN
                 2949
            
                WHEN old_id IN (1375) THEN
                 2950
            
                WHEN old_id IN (1373) THEN
                 2953
            
                WHEN old_id IN (33, 95, 140, 153, 1434, 10071, 702000010018, 999000010007) THEN
                 2959
            
                WHEN old_id IN (1097, 1114) THEN
                 2963
            
                WHEN old_id IN (702000010012) THEN
                 2970
            
                WHEN old_id IN (1433) THEN
                 2971
            
                WHEN old_id IN (1431) THEN
                 2972
            
                WHEN old_id IN (999000010027) THEN
                 2973
            
                WHEN old_id IN (4,
                                6,
                                8,
                                10,
                                12,
                                15,
                                20,
                                26,
                                28,
                                30,
                                32,
                                36,
                                37,
                                40,
                                43,
                                46,
                                51,
                                54,
                                56,
                                57,
                                60,
                                62,
                                64,
                                66,
                                70,
                                77,
                                97,
                                101,
                                103,
                                136,
                                137,
                                139,
                                144,
                                148,
                                152,
                                157,
                                162,
                                202,
                                204,
                                206,
                                211,
                                212,
                                213,
                                214,
                                215,
                                217,
                                219,
                                225,
                                227,
                                251,
                                253,
                                258,
                                287,
                                303,
                                305,
                                307,
                                309,
                                311,
                                351,
                                361,
                                401,
                                1093,
                                1099,
                                1106,
                                1110,
                                1116,
                                1123,
                                1175,
                                1178,
                                1181,
                                1183,
                                1185,
                                1212,
                                1213,
                                1214,
                                1215,
                                1216,
                                1217,
                                1218,
                                1219,
                                1220,
                                1221,
                                1222,
                                1223,
                                1231,
                                1232,
                                1233,
                                1234,
                                1235,
                                1236,
                                1237,
                                1238,
                                1239,
                                1240,
                                1241,
                                1242,
                                1250,
                                1259,
                                1262,
                                1274,
                                1283,
                                1286,
                                1312,
                                1355,
                                1358,
                                1376,
                                1426,
                                1497,
                                1510,
                                1517,
                                1520,
                                5015,
                                5016,
                                10006,
                                10012,
                                10014,
                                10016,
                                10022,
                                10024,
                                10027,
                                10029,
                                10052,
                                10062,
                                10066,
                                10068,
                                10074,
                                10076,
                                10102,
                                10106,
                                10200,
                                10501,
                                10512,
                                702000010003,
                                702000010005,
                                702000010020,
                                999000010003,
                                999000010013,
                                999000010020,
                                999000010024,
                                999000010030,
                                999000010031,
                                1539,
                                1549,
                                1544,
                                1534
                                ) THEN
                 2974
            
                WHEN old_id IN (1172, 1182, 1184, 10104) THEN
                 2979
            
                WHEN old_id IN (1310) THEN
                 2980
            
                WHEN old_id IN (99, 1441) THEN
                 2981
            
                WHEN old_id IN (1311) THEN
                 2982
            
                WHEN old_id IN (1260, 1261, 1284, 1285) THEN
                 2983
            
                WHEN old_id IN (10100) THEN
                 2984
            
                WHEN old_id IN (75, 999000010018) THEN
                 2985
            
                WHEN old_id IN (10510) THEN
                 2986
            
                WHEN old_id IN (10103) THEN
                 2988
            
                WHEN old_id IN (18,
                                69,
                                89,
                                142,
                                146,
                                150,
                                155,
                                1092,
                                1098,
                                1105,
                                1109,
                                1115,
                                1122,
                                1256,
                                1280,
                                1352,
                                1496,
                                1516,
                                1519,
                                10055,
                                10064,
                                10070,
                                10073,
                                10078,
                                10080,
                                999000010010,
                                999000010023,
                                1542,
                                1532
                                ) THEN
                 2989
            
                WHEN old_id IN (130, 131, 1254, 1278, 5011, 5012) THEN
                 2990
            
                WHEN old_id IN (1130, 10017) THEN
                 2991
            
                WHEN old_id IN (1371, 1546, 1536) THEN
                 2992
            
                WHEN old_id IN (100, 1104, 1121, 10054, 10058, 10077) THEN
                 2993
            
                WHEN old_id IN (132, 133, 1422, 5013, 5014) THEN
                 2994
            
                WHEN old_id IN (1257, 1281) THEN
                 2996
            
                WHEN old_id IN (96, 10010) THEN
                 2997
            
                WHEN old_id IN (92, 1450, 702000010017) THEN
                 2999
            
                WHEN old_id IN (76, 702000010019, 999000010019) THEN
                 3000
            
                WHEN old_id IN
                     (93, 1102, 1119, 1173, 1370, 10101, 702000010001, 702000010004, 999000010001, 999000010028) THEN
                 3002
            
                WHEN old_id IN (1091, 1108) THEN
                 3003
            
                WHEN old_id IN (83) THEN
                 3004
            
                WHEN old_id IN (999000010008) THEN
                 3005
            
                WHEN old_id IN (67, 71, 78, 1425, 1436, 999000010014) THEN
                 3006
            
                WHEN old_id IN (1103, 1120, 10057, 10059, 10060, 10511, 999000010021, 1547, 1537) THEN
                 3007
            
                WHEN old_id IN (1131, 1258, 1282) THEN
                 3008
            
                WHEN old_id IN (1372) THEN
                 3009
            
                WHEN old_id IN (223) THEN
                 3013
            
                WHEN old_id IN (1332) THEN
                 3016
            
                WHEN old_id IN (10019) THEN
                 3017
            
                WHEN old_id IN (10072, 999000010011) THEN
                 3018
            
                WHEN old_id IN (25, 1331) THEN
                 3019
            
                WHEN old_id IN (1437) THEN
                 3026
            
                WHEN old_id IN (1224, 1225, 1226, 1243, 1244, 1245, 1263, 1264, 1265, 1266, 1287, 1288, 1289, 1290) THEN
                 3028
            
                WHEN old_id IN (1255, 1279) THEN
                 3030
            
                WHEN old_id IN (1515) THEN
                 3034
            
                WHEN old_id IN (86, 702000010013, 999000010012) THEN
                 3035
            
                WHEN old_id IN (1439) THEN
                 3036
            
                WHEN old_id IN (10009) THEN
                 3039
            
                WHEN old_id IN (10020) THEN
                 3040
            
                WHEN old_id IN (73, 999000010016) THEN
                 3041
            
                WHEN old_id IN (999000010026) THEN
                 3042
            
                WHEN old_id IN (74, 999000010017) THEN
                 3043
            
                WHEN old_id IN (1356) THEN
                 3045
            
                WHEN old_id IN (1357) THEN
                 3046
            
                WHEN old_id IN (1171, 10011, 702000010009) THEN
                 3047
            
                WHEN old_id IN (999000010005) THEN
                 3048
            
                WHEN old_id IN (999000010004) THEN
                 3049
            
                WHEN old_id IN (1330) THEN
                 3050
            
                WHEN old_id IN (90) THEN
                 3051
            
                WHEN old_id IN (1350) THEN
                 3052
            
                WHEN old_id IN (1353) THEN
                 3053
            
                WHEN old_id IN (91) THEN
                 3054
            
                WHEN old_id IN (88) THEN
                 3055
            
                WHEN old_id IN (94) THEN
                 3056
            
                WHEN old_id IN (702000010016) THEN
                 3058
            
                WHEN old_id IN (702000010007) THEN
                 3060
            
                WHEN old_id IN (702000010008) THEN
                 3061
            
                WHEN old_id IN (702000010006) THEN
                 3062
            
                WHEN old_id IN (81) THEN
                 3063
            
                WHEN old_id IN (1438) THEN
                 3064
            
                WHEN old_id IN (281, 1252, 1276) THEN
                 3066
            
                WHEN old_id IN (24, 286) THEN
                 3069
            
                WHEN old_id IN (72, 80, 999000010015) THEN
                 3075
            
                WHEN old_id IN (10202) THEN
                 3076
            
                WHEN old_id IN (1440, 999000010025) THEN
                 3077
            
                WHEN old_id IN (14, 42, 45, 55, 1390, 1470, 10051, 10201, 999000010029, 1548, 1543, 1538, 1533) THEN
                 3078
                ELSE
                 2974 --other
            END CASE
      INTO l_result
      FROM dual;

    RETURN l_result;
END;


DROP FUNCTION REASONS_NEW_ID;
