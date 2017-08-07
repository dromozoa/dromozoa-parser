local lexer = require "dromozoa.parser.lexer"
local _ = {}
_[1] = {8,"\0"}
_[2] = {_[1]}
_[3] = {8,"\12"}
_[4] = {_[3]}
_[5] = {8,"\
"}
_[6] = {_[5]}
_[7] = {8,"\13"}
_[8] = {_[7]}
_[9] = {8,"\9"}
_[10] = {_[9]}
_[11] = {8,"\11"}
_[12] = {_[11]}
_[13] = {11,3,-1}
_[14] = {12,36}
_[15] = {17,-9}
_[16] = {13}
_[17] = {_[13],_[14],_[15],_[16]}
_[18] = {12,16}
_[19] = {_[13],_[18],_[16]}
_[20] = {16,3,6,9,12}
_[21] = {_[20]}
_[22] = {15,3,-1}
_[23] = {_[22]}
_[24] = {15,4,-2}
_[25] = {_[24]}
_[26] = {11,2,-1}
_[27] = {_[26]}
_[28] = {}
_[29] = {4,2}
_[30] = {_[29]}
_[31] = {4,3}
_[32] = {_[31]}
_[33] = {_[2],_[4],_[6],_[8],_[10],_[12],_[17],_[19],_[21],_[23],_[25],_[27],_[28],_[28],_[28],_[28],_[28],_[30],_[28],_[28],_[28],_[28],_[28],_[32],_[32]}
_[34] = {2,3,3,3,3,3,4,5,6,6,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20}
_[35] = {1,2,3,4,5,6,7,8,9,10,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}
_[36] = {[27]=20,[28]=13}
_[37] = {[28]=13}
_[38] = {[27]=22,[28]=13}
_[39] = {[27]=24,[28]=13}
_[40] = {[27]=16,[28]=13}
_[41] = {[27]=17,[28]=13}
_[42] = {[27]=21,[28]=13}
_[43] = {[27]=20,[28]=1,[30]=32,[31]=38,[32]=35,[33]=35,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[45]=9}
_[44] = {[27]=20,[30]=32,[31]=38,[32]=35,[33]=35,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[45]=9}
_[45] = {[27]=20,[30]=32,[31]=38,[32]=35,[33]=36,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[45]=9}
_[46] = {[27]=20,[28]=13,[46]=23}
_[47] = {[22]=46,[27]=18,[28]=13}
_[48] = {[27]=20,[29]=7,[30]=32,[31]=38,[32]=35,[33]=36,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[45]=9}
_[49] = {[27]=20,[29]=7,[30]=32,[31]=38,[32]=35,[33]=35,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[44]=37,[45]=9}
_[50] = {[27]=20,[28]=14,[29]=7,[30]=33,[31]=38,[32]=35,[33]=35,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[43]=44,[44]=37,[45]=9}
_[51] = {[27]=20,[29]=7}
_[52] = {[27]=20,[28]=14,[29]=7}
_[53] = {[27]=25,[28]=13}
_[54] = {[10]=42,[27]=28,[28]=13}
_[55] = {[25]=26,[28]=13}
_[56] = {[27]=20}
_[57] = {[27]=20,[28]=29,[29]=7,[30]=32,[31]=38,[32]=35,[33]=35,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[44]=37,[45]=9}
_[58] = {[27]=20,[28]=2,[29]=7,[30]=32,[31]=38,[32]=35,[33]=35,[34]=39,[35]=41,[36]=40,[37]=45,[38]=8,[39]=39,[40]=10,[41]=11,[44]=37,[45]=9}
_[59] = {[27]=20,[28]=3,[29]=7}
_[60] = {[27]=20,[28]=4,[29]=7}
_[61] = {[27]=20,[28]=5,[29]=7}
_[62] = {[27]=20,[28]=30,[29]=7,[42]=43}
_[63] = {[27]=20,[28]=6,[29]=7}
_[64] = {[27]=20,[28]=31,[29]=7}
_[65] = {[27]=19,[28]=13,[30]=34}
_[66] = {[27]=15,[28]=13}
_[67] = {[28]=13,[39]=12}
_[68] = {_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[37],_[36],_[36],_[36],_[38],_[39],_[40],_[41],_[36],_[36],_[42],_[36],_[43],_[44],_[44],_[44],_[44],_[44],_[44],_[44],_[45],_[45],_[46],_[36],_[36],_[36],_[36],_[47],_[36],_[48],_[48],_[49],_[50],_[49],_[49],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[52],_[51],_[51],_[51],_[52],_[51],_[51],_[51],_[53],_[54],_[37],_[55],_[56],_[36],_[48],_[48],_[57],_[50],_[49],_[58],_[51],_[51],_[51],_[51],_[51],_[51],_[51],_[59],_[51],_[51],_[51],_[60],_[52],_[61],_[62],_[63],_[52],_[64],_[51],_[51],_[65],_[66],_[67],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],_[36],[0]=_[36]}
_[69] = {accept_states=_[35],max_state=46,start_state=27,transitions=_[68]}
_[70] = {accept_to_actions=_[33],accept_to_symbol=_[34],automaton=_[69]}
_[71] = {5}
_[72] = {_[71]}
_[73] = {_[28],_[28],_[72]}
_[74] = {21,22,23}
_[75] = {1,2,3}
_[76] = {[4]=2}
_[77] = {[1]=1,[4]=1}
_[78] = {[4]=3}
_[79] = {_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[76],_[28],_[28],_[28],_[77],_[77],_[77],_[77],_[77],_[77],_[77],_[77],_[77],_[77],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[78],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],_[28],[0]=_[28]}
_[80] = {accept_states=_[75],max_state=4,start_state=4,transitions=_[79]}
_[81] = {accept_to_actions=_[73],accept_to_symbol=_[74],automaton=_[80]}
_[82] = {8,"\8"}
_[83] = {_[82]}
_[84] = {8,"-"}
_[85] = {_[84]}
_[86] = {_[2],_[4],_[6],_[8],_[10],_[12],_[17],_[19],_[21],_[23],_[25],_[27],_[28],_[28],_[83],_[85],_[28],_[72]}
_[87] = {2,3,3,3,3,3,4,5,6,6,6,7,8,24,25,26,27,28}
_[88] = {1,2,3,4,5,6,7,8,9,10,10,11,12,13,14,15,18,17}
_[89] = {[19]=15,[20]=13}
_[90] = {[19]=18,[20]=13}
_[91] = {[19]=15,[20]=1,[22]=24,[23]=30,[24]=27,[25]=27,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[37]=9}
_[92] = {[19]=15,[22]=24,[23]=30,[24]=27,[25]=27,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[37]=9}
_[93] = {[19]=15,[22]=24,[23]=30,[24]=27,[25]=28,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[37]=9}
_[94] = {[19]=15,[21]=7,[22]=24,[23]=30,[24]=27,[25]=28,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[37]=9}
_[95] = {[19]=15,[21]=7,[22]=24,[23]=30,[24]=27,[25]=27,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[36]=29,[37]=9}
_[96] = {[19]=15,[20]=14,[21]=7,[22]=25,[23]=30,[24]=27,[25]=27,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[35]=36,[36]=29,[37]=9}
_[97] = {[19]=15,[21]=7}
_[98] = {[19]=15,[20]=14,[21]=7}
_[99] = {[10]=34,[19]=20,[20]=13}
_[100] = {[19]=17,[20]=13}
_[101] = {[19]=15}
_[102] = {[19]=15,[20]=16,[21]=7,[22]=24,[23]=30,[24]=27,[25]=28,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[37]=9}
_[103] = {[19]=15,[20]=21,[21]=7,[22]=24,[23]=30,[24]=27,[25]=27,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[36]=29,[37]=9}
_[104] = {[19]=15,[20]=2,[21]=7,[22]=24,[23]=30,[24]=27,[25]=27,[26]=31,[27]=33,[28]=32,[29]=37,[30]=8,[31]=31,[32]=10,[33]=11,[36]=29,[37]=9}
_[105] = {[19]=15,[20]=3,[21]=7}
_[106] = {[19]=15,[20]=4,[21]=7}
_[107] = {[19]=15,[20]=5,[21]=7}
_[108] = {[19]=15,[20]=22,[21]=7,[34]=35}
_[109] = {[19]=15,[20]=6,[21]=7}
_[110] = {[19]=15,[20]=23,[21]=7}
_[111] = {[19]=15,[20]=13,[22]=26}
_[112] = {[19]=15,[20]=13,[31]=12}
_[113] = {_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[90],_[89],_[89],_[91],_[92],_[92],_[92],_[92],_[92],_[92],_[92],_[93],_[93],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[94],_[94],_[95],_[96],_[95],_[95],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[98],_[97],_[97],_[97],_[98],_[97],_[97],_[97],_[89],_[99],_[100],_[89],_[101],_[89],_[94],_[102],_[103],_[96],_[95],_[104],_[97],_[97],_[97],_[97],_[97],_[97],_[97],_[105],_[97],_[97],_[97],_[106],_[98],_[107],_[108],_[109],_[98],_[110],_[97],_[97],_[111],_[89],_[112],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],_[89],[0]=_[89]}
_[114] = {accept_states=_[88],max_state=37,start_state=19,transitions=_[113]}
_[115] = {accept_to_actions=_[86],accept_to_symbol=_[87],automaton=_[114]}
_[116] = {_[70],_[81],_[115]}
return function () return lexer(_[116]) end
