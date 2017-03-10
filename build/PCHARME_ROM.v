/*
      Auto generated ROM file for Acorn Atom 
     ROM       FileName             Address Size
     PCHARME_ROM roms/pcharme.rom     A000     4096 
*/
 
reg [7:0] D_IN_a000;
SB_RAM512x8 PCHARME_ROM_a000 (
     .RDATA (D_IN_a000),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_a000.INIT_0 = 256'h881c5c388021462ec137483388255778cc73af44d700e41c0a570c0045d7b200 ;
  defparam PCHARME_ROM_a000.INIT_1 = 256'hc02690d00007ff0025f1f0c34436aa552628a4d3ef08c6130c45042085385502 ;
  defparam PCHARME_ROM_a000.INIT_2 = 256'hf0e88c0759000c25d9abfde14c00043ada14b46858b85954a420b86a48446c14 ;
  defparam PCHARME_ROM_a000.INIT_3 = 256'h9328c43156e08e000c6dec6358339967127aac32563ccc3616d48c20e3b44810 ;
  defparam PCHARME_ROM_a000.INIT_4 = 256'he6b3ee4054e6a4826390ca1644afee04c327e8340150cc0cd23999609278ad7c ;
  defparam PCHARME_ROM_a000.INIT_5 = 256'hc723c062c905e098584069154291e9b6e701e990e091e99ee2100002c400e3b7 ;
  defparam PCHARME_ROM_a000.INIT_6 = 256'h8855ecc91d55ea36f64054a3f5824325fb0158eaa0c60036db02f485d049eb05 ;
  defparam PCHARME_ROM_a000.INIT_7 = 256'h08004eeb880de408e18c60b1fa95d700cc0258e31d54cc31bdfc5c1415d4ca11 ;
  defparam PCHARME_ROM_a000.INIT_8 = 256'h1d548c20fc90590088edf0005d405528ce05cc595be34901ef29da40c901e83b ;
  defparam PCHARME_ROM_a000.INIT_9 = 256'hf0c85d55544bac284129e7015dbff5c68c2815fe4c118903d10835f5cc166411 ;
  defparam PCHARME_ROM_a000.INIT_A = 256'h4c1198182e085c40c925e8944c44e306ce10c940f8d85d00d736d12888d9d841 ;
  defparam PCHARME_ROM_a000.INIT_B = 256'h80278c03c87e30e088070ca34c518813ceae4c5566d198721576ce10d8084fa2 ;
  defparam PCHARME_ROM_a000.INIT_C = 256'h2813c5230005cc92377dc426368028278681625b9462501168c326828822660c ;
  defparam PCHARME_ROM_a000.INIT_D = 256'h0441c8447674d9082677d06300a988226371d46200f6dd22227bd06322877c36 ;
  defparam PCHARME_ROM_a000.INIT_E = 256'hac2801a5c7006c9059368e00662af872260ad86270943278bc22631dc8330fd5 ;
  defparam PCHARME_ROM_a000.INIT_F = 256'h1d556608d75766698b07670aec38511ca6002219ed28722ead290408f2107369 ;
reg [7:0] D_IN_a200;
SB_RAM512x8 PCHARME_ROM_a200 (
     .RDATA (D_IN_a200),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_a200.INIT_0 = 256'h227462333107c419885960b3332664b920627308368bcc135cefd9a0ff448874 ;
  defparam PCHARME_ROM_a200.INIT_1 = 256'h203226089327d81620a465223124c2139990363134e831af601b1b319cbb34aa ;
  defparam PCHARME_ROM_a200.INIT_2 = 256'h31b97036200e5b8899104eb15c36dd2a756420fc24223304c129999265216406 ;
  defparam PCHARME_ROM_a200.INIT_3 = 256'h726b9c80643164ac2423327a1b86d834312770b420867180332ec4b199987034 ;
  defparam PCHARME_ROM_a200.INIT_4 = 256'h8ddf242030fc24773169d51fd9832422661a74f424223609c830257971823394 ;
  defparam PCHARME_ROM_a200.INIT_5 = 256'h98d6724924ae7708334970631c4075fd74fbac2a986a77557436242234094e98 ;
  defparam PCHARME_ROM_a200.INIT_6 = 256'h992572c3230075aa305ad0eb89987522320f7043255e758889cd70e921ff77a8 ;
  defparam PCHARME_ROM_a200.INIT_7 = 256'h36826033348a5d37d980225170eb3340cd23d8606396621061be641a7196d9a8 ;
  defparam PCHARME_ROM_a200.INIT_8 = 256'h6639c42ccc9524aa665c616226887ba1c83077d6642264de34f924823eaa8960 ;
  defparam PCHARME_ROM_a200.INIT_9 = 256'hcc826406663524027121e0b2882a6408205267206484b2408c2a201925027321 ;
  defparam PCHARME_ROM_a200.INIT_A = 256'hcd23201b60ba22086600a01cc83321ac64bb70867264305a64fc63622428d55f ;
  defparam PCHARME_ROM_a200.INIT_B = 256'h882f6032724a726270132700289bcd8370b275162608206a71aa22597241a033 ;
  defparam PCHARME_ROM_a200.INIT_C = 256'h7780643620d50ca8ccd5264d2402763cb32888af643266687456260a7408cee9 ;
  defparam PCHARME_ROM_a200.INIT_D = 256'h661071be2620221ac896882a660e61ea601a29a4c90023647043340bf449dc88 ;
  defparam PCHARME_ROM_a200.INIT_E = 256'h800774be722575aa643eaaff8c206476635924aa2225730a21276308db23cc91 ;
  defparam PCHARME_ROM_a200.INIT_F = 256'h7ef48ca8fba1603864bad9fa0ea8d5005500abea710d7722771b71aa247a5041 ;
reg [7:0] D_IN_a400;
SB_RAM512x8 PCHARME_ROM_a400 (
     .RDATA (D_IN_a400),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_a400.INIT_0 = 256'h18b9190510d0b201323ecd63e471b8311911b1a419325c0056fcee51dd6d00fe ;
  defparam PCHARME_ROM_a400.INIT_1 = 256'h31b49293c520c6d1913232d7987499eeecf11904b1b03ba730f4104bc714e479 ;
  defparam PCHARME_ROM_a400.INIT_2 = 256'h7113ecc34022cb034ed0ae50ea004410ccd312189830b075ee694c51b076329b ;
  defparam PCHARME_ROM_a400.INIT_3 = 256'he7a8cfa2824ed063888dd34b6c731680208c208dc25bc4674e638a04028ce0d3 ;
  defparam PCHARME_ROM_a400.INIT_4 = 256'h9870820dd161d4d40103df00c6c192478422501bad620e8018d19ee38ae448c0 ;
  defparam PCHARME_ROM_a400.INIT_5 = 256'hea33af014426a6520754c6047013b58292528a07f580c4c1126dae00508d014f ;
  defparam PCHARME_ROM_a400.INIT_6 = 256'ha8e0fa4119a6f49369054e91e0d1b322e611d64aac201906cc19110c4214e19d ;
  defparam PCHARME_ROM_a400.INIT_7 = 256'h8602df56e1908480510f8520fc69ab00411ff034fcd9db006117f4960032cf02 ;
  defparam PCHARME_ROM_a400.INIT_8 = 256'h46ab0600088547aa08937088009045882851d22080654780aa82ee415d54b583 ;
  defparam PCHARME_ROM_a400.INIT_9 = 256'hf44ab0f258413dfa8c00b660709a5c400622d6726980f890a7902e0818406490 ;
  defparam PCHARME_ROM_a400.INIT_A = 256'hf0c92c005031996dba78e6015172a400e49078eb8602555467099ad20040d805 ;
  defparam PCHARME_ROM_a400.INIT_B = 256'hf2048d238480581540472eaadfa379004421d56dac80a0884e2a1910cc84e498 ;
  defparam PCHARME_ROM_a400.INIT_C = 256'he600d82758cf0c00cc3845ee0c00d238d4231858d8860da12482d8976845ae80 ;
  defparam PCHARME_ROM_a400.INIT_D = 256'h19c0cfa382a34428d8321cc4b2f8c6b600778c22e474ea6d1850140bc830b310 ;
  defparam PCHARME_ROM_a400.INIT_E = 256'hcd370c82ab00f1881078d8699628c433b422239460b19bea6701d862ac994811 ;
  defparam PCHARME_ROM_a400.INIT_F = 256'h06801e005536db02a0d1facbf7555463a602b1c045a3d8c2c490d35a8422c628 ;
reg [7:0] D_IN_a600;
SB_RAM512x8 PCHARME_ROM_a600 (
     .RDATA (D_IN_a600),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_a600.INIT_0 = 256'h86023c80f481190ac6425fbb8c82d228cc61441e80758480d8392c600c00584a ;
  defparam PCHARME_ROM_a600.INIT_1 = 256'hc123c7098822442694228207c832cde02ad15841888555282dc752c1d784490b ;
  defparam PCHARME_ROM_a600.INIT_2 = 256'ha16d5aeb9882f461ad604900ea3eeb01cd2b58c818004404a033738024b15069 ;
  defparam PCHARME_ROM_a600.INIT_3 = 256'h0c0fc123490aaa13490f88334395eebec914ecb2b240491ae212fac099114d20 ;
  defparam PCHARME_ROM_a600.INIT_4 = 256'ha8c4d64a8030e494493e4210584ada428881090a9e42a0814820e97941489240 ;
  defparam PCHARME_ROM_a600.INIT_5 = 256'h2488506ade052400ccc29cca02bb4d004667837706aa0993619914e002400188 ;
  defparam PCHARME_ROM_a600.INIT_6 = 256'h3d860680968044577faa86f2584b5242c30bcd214110cc92e195fc1e4c149cd4 ;
  defparam PCHARME_ROM_a600.INIT_7 = 256'h1428c136481adf42a1805066d0620c0fcb031106cd110030c42ce334e6105168 ;
  defparam PCHARME_ROM_a600.INIT_8 = 256'h0025cc49e1914013c3154099618542b1aa004eebe1924c1a9a42e0c4c31bc434 ;
  defparam PCHARME_ROM_a600.INIT_9 = 256'hd0c008157980a7c478c14901c70bd060bb845300a4c87249c3234d0bcb16e091 ;
  defparam PCHARME_ROM_a600.INIT_A = 256'hdd008dcc504308928daaeb850c10cc368bfa24a0c199e2b6e314c61ec9259c36 ;
  defparam PCHARME_ROM_a600.INIT_B = 256'haa904c1478e35b00ae625241d584e981ac8041184230d386d90aaee3dae3545f ;
  defparam PCHARME_ROM_a600.INIT_C = 256'h0cb050b6ccc677f8ae00ae98f61490c0ae8fc52b0801c888e5d018608e25ccbb ;
  defparam PCHARME_ROM_a600.INIT_D = 256'hc495e5aa20475c0044cf5982aeaffa311c407884a521ac02080135d543f99cc2 ;
  defparam PCHARME_ROM_a600.INIT_E = 256'h5018f7140620ca600027cc92cc31e5410c00fac11215aeaafb70590061975e10 ;
  defparam PCHARME_ROM_a600.INIT_F = 256'hc901223ec431f0682e8f49012291cc11d24a84274321c331c619c125c090c2c0 ;
reg [7:0] D_IN_a800;
SB_RAM512x8 PCHARME_ROM_a800 (
     .RDATA (D_IN_a800),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_a800.INIT_0 = 256'h4d20aa8c4651c64a9942861ea86cbb37ee115036e252068a5a05d25b8c02930f ;
  defparam PCHARME_ROM_a800.INIT_1 = 256'hd21edd06f1804860e30518b9f5c35122de464d88aa04405bf06449ac4e14d262 ;
  defparam PCHARME_ROM_a800.INIT_2 = 256'h3aea41c2d231996738d0299058142a04d7220930441a80340d28fe548100b1c2 ;
  defparam PCHARME_ROM_a800.INIT_3 = 256'h048070c0d60f8c02820bec2cf064b8700c00055be641d8c4b0d22480920a0843 ;
  defparam PCHARME_ROM_a800.INIT_4 = 256'h4c62b4c2d87911ba0c002805df808a15c210dd69e1d3860a8817ce3866006541 ;
  defparam PCHARME_ROM_a800.INIT_5 = 256'haa2d5941ccfbbaca20b1e43b10e00814ccbbfb9a75a0f3c3f98a09455028f240 ;
  defparam PCHARME_ROM_a800.INIT_6 = 256'hba4584a88ab6c819808d53c1e7510213c033002dd9624751c46600668c22f520 ;
  defparam PCHARME_ROM_a800.INIT_7 = 256'hc03316488833c8311ce80805fbc9f254f88509c5105096e2144aa293d5a2444b ;
  defparam PCHARME_ROM_a800.INIT_8 = 256'haf005d64a1825aceaa050c26e1d3be4dc6064844e4337b2270b1828084288296 ;
  defparam PCHARME_ROM_a800.INIT_9 = 256'hcdd9001c4c04385cd300a0255f205c54110ff1280273fa110027f743e4d161c4 ;
  defparam PCHARME_ROM_a800.INIT_A = 256'h00194911aa05d59f4d51f462669024f4a6a8d740f1085a460855e19908af5d00 ;
  defparam PCHARME_ROM_a800.INIT_B = 256'h221d82530a668a36f595730986020d2cdf22a094f0b8d36c0d0055608928d8cc ;
  defparam PCHARME_ROM_a800.INIT_C = 256'hd900f244880d5f08c351a27565310814cc86991a30a12608930230759b32b185 ;
  defparam PCHARME_ROM_a800.INIT_D = 256'hcf468805f5e9c859a07bc49b5d40a188fa44a2855f3d4951889945395c40ffe0 ;
  defparam PCHARME_ROM_a800.INIT_E = 256'he1876231821777088a02e4c1faebdc04b05af0e64c412231c810888d55284854 ;
  defparam PCHARME_ROM_a800.INIT_F = 256'h74b470c86a408885ecb84905fe968882e42ec19b481198a8ee41ee3ea25504a2 ;
reg [7:0] D_IN_aa00;
SB_RAM512x8 PCHARME_ROM_aa00 (
     .RDATA (D_IN_aa00),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_aa00.INIT_0 = 256'h30e0889e4c91184000394e11f6c062b274e1e214eae54c00f03fc48e70a4445a ;
  defparam PCHARME_ROM_aa00.INIT_1 = 256'h0c00889b48914940e61322b660b1414bee110827e093aa08c6431840a085ec13 ;
  defparam PCHARME_ROM_aa00.INIT_2 = 256'h04027fbfdee18caa8304b1200f604c11f6c026a261e1e643a8404900f224258b ;
  defparam PCHARME_ROM_aa00.INIT_3 = 256'hc8111c60a168c96b489908146c114960e839081bc6135830f53c0622ce36a0d5 ;
  defparam PCHARME_ROM_aa00.INIT_4 = 256'hc23181334d1bda17eac7a600bc80d0c56580081bca139cc88094481b9e42aaaf ;
  defparam PCHARME_ROM_aa00.INIT_5 = 256'h0c0a8a47d5804114d81cfa7aa3558620a830d236cc61ddce848a5c4144c3eb14 ;
  defparam PCHARME_ROM_aa00.INIT_6 = 256'h003b7982d65fd863c325c4315c74f928fe76f700119fec11ac944502d00487a3 ;
  defparam PCHARME_ROM_aa00.INIT_7 = 256'h2c800c60e469504ddb11185ad563d3206c36085f8c220285dc9ed0da084598d0 ;
  defparam PCHARME_ROM_aa00.INIT_8 = 256'h0c0ada1391c010508818781414609c68d289fd80ec80d8e3b078190044bbd462 ;
  defparam PCHARME_ROM_aa00.INIT_9 = 256'h51648c28c6669579a420e6c375b186228025fa3ca3155522ac10f8c1770cc323 ;
  defparam PCHARME_ROM_aa00.INIT_A = 256'hc461ff3b0600f08da1c5185a82125016c441dfe60488dd1d4441dd40d32ad03c ;
  defparam PCHARME_ROM_aa00.INIT_B = 256'h987289b16b911910c63bdc62fb2af2158d3d2ca858544523ae0044649d798628 ;
  defparam PCHARME_ROM_aa00.INIT_C = 256'h4c00d73fdd23ae82b340ec84f085585b860239c0c62ad038fc818e8864c445aa ;
  defparam PCHARME_ROM_aa00.INIT_D = 256'hf715555baca888a26caaf714db0aa092500afacaddb7dd6c840031e0cda12a80 ;
  defparam PCHARME_ROM_aa00.INIT_E = 256'hd24ad575ff90a60004d4ec41a88465808602da630010cd08155ff8e939e06d89 ;
  defparam PCHARME_ROM_aa00.INIT_F = 256'h050a88656d088a44d854d300d8764c8b0c00ddd5fcd90c00d661d1228830d882 ;
reg [7:0] D_IN_ac00;
SB_RAM512x8 PCHARME_ROM_ac00 (
     .RDATA (D_IN_ac00),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_ac00.INIT_0 = 256'h88150034d53df189a48299475d00a894f01af09a5d1404209c2c87208039e589 ;
  defparam PCHARME_ROM_ac00.INIT_1 = 256'hae0258639f72a480820ae6130228ce268c80b38c9255b9a4b186921b8a53aaee ;
  defparam PCHARME_ROM_ac00.INIT_2 = 256'h75d184804c5f5651a48083c0a02ae600645d06670e20df77f4f38e00e480c74b ;
  defparam PCHARME_ROM_ac00.INIT_3 = 256'h26228420771dd121a4286e1859502620d527d30a8f42225bd063b1c0c70bdf17 ;
  defparam PCHARME_ROM_ac00.INIT_4 = 256'hb6402880e0b3946a1c40f07bc1cf1850e4185e560c00f4c402790844266c8420 ;
  defparam PCHARME_ROM_ac00.INIT_5 = 256'he2105d80e4d6fa4986424c00c8ced52a21f1d8e3a02d4c00a082643b4900e039 ;
  defparam PCHARME_ROM_ac00.INIT_6 = 256'h77948804f1a88b135d14a0084e0258415170b878e1485f0a5841586b89094633 ;
  defparam PCHARME_ROM_ac00.INIT_7 = 256'h06a7ea1104a7bc9327c0cb420e856321d0620410cd930405c901a11be5b30c10 ;
  defparam PCHARME_ROM_ac00.INIT_8 = 256'hff117380a6075189ae0541a3f5d7b2692e8f4d01a080c4808490763c8024e180 ;
  defparam PCHARME_ROM_ac00.INIT_9 = 256'h306a080120c167798823004def502372dd225125fa41a801a2546779cd64be20 ;
  defparam PCHARME_ROM_ac00.INIT_A = 256'hd9a2df8a70e1a5c0f5aa1fed5841124d5700e1af5ae91c4046cc8a0128c4e5d3 ;
  defparam PCHARME_ROM_ac00.INIT_B = 256'h14618c2800124c9692c00407cc1149e44451d814040aee45d380f5aa5ea84c55 ;
  defparam PCHARME_ROM_ac00.INIT_C = 256'h500487018682f8c00116040adab614908c00ced89ccb840870b5e0c72ea04c50 ;
  defparam PCHARME_ROM_ac00.INIT_D = 256'h7c113cc029c0099179948e10511c80ac512089196d11f8c1b895ae28f655c180 ;
  defparam PCHARME_ROM_ac00.INIT_E = 256'hf928ae6ac604eff48ee24815e541d0367ba8d992dca869075d00a282cc220485 ;
  defparam PCHARME_ROM_ac00.INIT_F = 256'he9854013aa05aab4e5f60804de454549cdb5f120d5285620dd08ea3a1250a051 ;
reg [7:0] D_IN_ae00;
SB_RAM512x8 PCHARME_ROM_ae00 (
     .RDATA (D_IN_ae00),
     .RCLK(clk),
     .RCLKE(1'b1),
     .RADDR(cpu_address[8:0]),
     .RE(1'b1)
     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA
);
  defparam PCHARME_ROM_ae00.INIT_0 = 256'h3a408062ffd089d2b258d6e24900720a943ca197d4025d11f182880258107afc ;
  defparam PCHARME_ROM_ae00.INIT_1 = 256'h89622aecc4227ff0d9622c00c67e94232e0079224491d8824a91f770a6050c00 ;
  defparam PCHARME_ROM_ae00.INIT_2 = 256'hcd222286c0730038cc63006dfb000001cc8667828026425c88376eae80636ba2 ;
  defparam PCHARME_ROM_ae00.INIT_3 = 256'he746d42353a0ea40f20894368dea57da59448ca86da208047c5477d0d1620422 ;
  defparam PCHARME_ROM_ae00.INIT_4 = 256'hcc3377d0e714125ae0c67d80555850c380a382929973005d04c180a38285cd73 ;
  defparam PCHARME_ROM_ae00.INIT_5 = 256'h9c459a7a085489a8bfdf481115459c939dfd66131d5442399d663ebb81621d76 ;
  defparam PCHARME_ROM_ae00.INIT_6 = 256'hea39a244e4c9b48040020154c2d3ea0a2bd75c54508dea10f658c83c976ad830 ;
  defparam PCHARME_ROM_ae00.INIT_7 = 256'h0f81a480001254148a86e708c430fb942e280c14c894a1b742910c11621c813c ;
  defparam PCHARME_ROM_ae00.INIT_8 = 256'hfac07a685805f259842017c6ee00a20ce424d090fe3286004498f1960e00f886 ;
  defparam PCHARME_ROM_ae00.INIT_9 = 256'h86a2c94bea909fa2c23ad262110d403a9ea2a885e218c163e618f8275ad192d0 ;
  defparam PCHARME_ROM_ae00.INIT_A = 256'h58111348c521050d518039a5f213d86274c5a508b36265a1aa094600445d016f ;
  defparam PCHARME_ROM_ae00.INIT_B = 256'h034049c1e4b8c9164810e1c0449066d58e47a480cc5c7f6b0c008cd1d9aa190e ;
  defparam PCHARME_ROM_ae00.INIT_C = 256'hc579021ddd280820c42641bcc4326683cd770c0a916214b3c1373691c936ee19 ;
  defparam PCHARME_ROM_ae00.INIT_D = 256'h942200a7c8326396c03262c0d531f1a8eb9d5c10f448f2c831e0410188091028 ;
  defparam PCHARME_ROM_ae00.INIT_E = 256'hb8d7268099624381b5fe46bb70e03368c1239dffcc9362ca806651a89d226699 ;
  defparam PCHARME_ROM_ae00.INIT_F = 256'h6c000222ce261124e039b020ec434c45790072d6e4290408ce04379084224456 ;
wire [7:0] PCHARME_ROM_out; 
 assign PCHARME_ROM_out =  (latched_cpu_addr[15:9] == 7'h57) ? D_IN_ae00 :  (latched_cpu_addr[15:9] == 7'h56) ? D_IN_ac00 :  (latched_cpu_addr[15:9] == 7'h55) ? D_IN_aa00 :  (latched_cpu_addr[15:9] == 7'h54) ? D_IN_a800 :  (latched_cpu_addr[15:9] == 7'h53) ? D_IN_a600 :  (latched_cpu_addr[15:9] == 7'h52) ? D_IN_a400 :  (latched_cpu_addr[15:9] == 7'h51) ? D_IN_a200 :  (latched_cpu_addr[15:9] == 7'h50) ? D_IN_a000 :  0;