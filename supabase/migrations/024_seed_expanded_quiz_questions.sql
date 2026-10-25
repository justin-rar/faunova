-- ==============================================================================
-- Migration 024: Seed 28 Soal Tambahan Kuis Biologi Satwa Liar (Total 40 Soal)
-- Menambah variasi soal satwa endemik Nusantara, ordo taksonomi, adaptasi morfologi, dan biogeografi
-- ==============================================================================

INSERT INTO public.quiz_questions (category, question, options, correct_option, explanation) VALUES
(
    'Mamalia',
    'Tarsius (Tarsius spectrumgurskyae) adalah primata karnivora terkecil yang matanya tidak dapat melirik, namun dapat memutar kepalanya hingga...',
    '["180 derajat ke kiri dan ke kanan", "90 derajat total", "45 derajat saja", "360 derajat putaran penuh sekaligus"]'::jsonb,
    0,
    'Tarsius memiliki adaptasi leher yang sangat fleksibel sehingga dapat memutar kepalanya 180 derajat ke kiri maupun ke kanan untuk memantau mangsa di malam hari.'
),
(
    'Mamalia',
    'Babirusa (Babyrousa babyrussa) adalah satwa unik endemik Sulawesi dengan ciri khas taring atas melengkung ke atas yang tumbuh menembus...',
    '["Rahang bawah bagian depan", "Gusi belakang geraham", "Kulit moncong bagian atas", "Tulang pelipis mata"]'::jsonb,
    2,
    'Pada Babirusa jantan, taring atas tumbuh ke atas mencuat menembus kulit moncong atas dan melengkung ke arah dahi.'
),
(
    'Mamalia',
    'Pesut Mahakam (Orcaella brevirostris) adalah mamalia lumba-lumba air tawar langka berstatus Kritis (CR) yang mendiami aliran sungai...',
    '["Sungai Kapuas di Kalimantan Barat", "Sungai Mahakam di Kalimantan Timur", "Sungai Barito di Kalimantan Selatan", "Sungai Musi di Sumatera Selatan"]'::jsonb,
    1,
    'Pesut Mahakam hidup di perairan tawar Sungai Mahakam, Kalimantan Timur, dan populasinya saat ini terancam kritis akibat jaring nelayan dan lalu lintas tongkang.'
),
(
    'Aves',
    'Kasuari Gelambir Ganda (Casuarius casuarius) dari Papua memiliki pertahanan kaki yang sangat berbahaya berupa...',
    '["Sengatan racun di tumit", "Cakar tengah lurus tajam menyerupai belati", "Selaput renang keras bergerigi", "Kelenjar getah perekat mangsa"]'::jsonb,
    1,
    'Jari kaki bagian dalam Kasuari dilengkapi cakar lurus tajam sepanjang hingga 12 cm yang dapat mematikan predator saat melompat menendang.'
),
(
    'Aves',
    'Elang Jawa (Nisaetus bartelsi) adalah burung pemangsa endemik Pulau Jawa yang menjadi figur inspirasi lambang nasional Indonesia yaitu...',
    '["Burung Maleo", "Cenderawasih Emas", "Burung Garuda", "Kakatua Putih"]'::jsonb,
    2,
    'Jambul khas dan ciri fisik Elang Jawa menjadikannya satwa langka yang diidentikkan dengan lambang negara Burung Garuda.'
),
(
    'Biogeografi',
    'Garis khayal yang membatasi fauna tipe Peralihan (Wallacea) dengan fauna tipe Australis di kawasan timur kepulauan Indonesia disebut...',
    '["Garis Wallace", "Garis Weber", "Garis Lydekker", "Garis Khatulistiwa"]'::jsonb,
    1,
    'Garis Weber menggambarkan batas persebaran fauna Australis (seperti marsupial dan cenderawasih) dengan kawasan kepulauan peralihan Sulawesi dan Nusa Tenggara.'
),
(
    'Ikan',
    'Coelacanth Sulawesi (Latimeria menadoensis) sering dijuluki "fosil hidup" karena morfologinya tidak banyak berubah sejak masa purba, ditemukan di perairan...',
    '["Selat Sunda", "Teluk Cenderawasih", "Laut Jawa", "Manado Tua, Sulawesi Utara"]'::jsonb,
    3,
    'Spesimen Coelacanth hidup ditemukan nelayan di perairan pulau vulkanik Manado Tua pada tahun 1997-1998, menggemparkan dunia sains internasional.'
),
(
    'Mamalia',
    'Trenggiling Jawa (Manis javanica) melindungi dirinya dari ancaman predator dengan menggulung tubuh dan mengandalkan sisik keras berbahan...',
    '["Keratin (protein penyusun kuku dan rambut)", "Kalsium karbonat tempurung", "Lapisan kitin exoskeleton", "Serat kolagen bertulang rawan"]'::jsonb,
    0,
    'Sisik trenggiling tersusun dari keratin padat, bahan yang sama dengan kuku manusia dan tanduk badak, sangat kuat menahan gigitan predator.'
),
(
    'Aves',
    'Kakatua Raja (Probosciger aterrimus) memiliki ciri fisik unik burung kakatua hitam berukuran besar dari Papua yang paruhnya berfungsi memecah...',
    '["Daging bangkai mamalia besar", "Biji kenari keras dan kacang hutan berkayu", "Cangkang kerang laut tebal", "Kulit kura-kura sungai"]'::jsonb,
    1,
    'Paruh Kakatua Raja sangat besar dan memiliki kekuatan rahang luar biasa untuk membuka biji kenari liar (Canarium) yang sangat keras.'
),
(
    'Ikan',
    'Ikan Arwana Super Red (Scleropages formosus) yang terkenal bernilai tinggi di kalangan pehobi merupakan spesies endemik dari...',
    '["Danau Toba, Sumatera Utara", "Sungai Kapuas dan Danau Sentarum, Kalimantan Barat", "Danau Matano, Sulawesi Selatan", "Sungai Mamberamo, Papua"]'::jsonb,
    1,
    'Varietas Super Red asli hanya hidup secara endemik di DAS Sungai Kapuas dan sistem perairan Danau Sentarum, Kalimantan Barat.'
),
(
    'Aves',
    'Burung Rangkong / Enggang Badak (Buceros rhinoceros) memiliki tonjolan mirip tanduk di atas paruhnya yang disebut casque, yang berfungsi untuk...',
    '["Memperkeras resonansi suara panggilan dan atraksi kawin", "Menyimpan cadangan air minum darurat", "Mengikis tanah liat tebing", "Menghasilkan racun pertahanan diri"]'::jsonb,
    0,
    'Casque berongga pada burung Rangkong berfungsi sebagai ruang resonansi akustik untuk memperkuat suara kuakan burung di kanopi hutan lebat.'
),
(
    'Mamalia',
    'Macan Dahan Kalimantan (Neofelis diardi) adalah kucing liar penghuni pohon (arboreal) yang memiliki proporsi taring...',
    '["Terpendek di antara keluarga kucing", "Paling rapuh dan tidak bergerigi", "Terpanjang dibanding ukuran tengkoraknya di antara felidae hidup", "Hanya tumbuh pada jantan dewasa"]'::jsonb,
    2,
    'Proporsi gigi taring Macan Dahan terhadap ukuran kepalanya adalah yang terbesar di antara seluruh spesies kucing liar yang masih hidup di bumi.'
),
(
    'Mamalia',
    'Kanguru Pohon Wondiwoi (Dendrolagus mayri) adalah mamalia berkantung (marsupial) endemik Papua yang hidup di...',
    '["Rawa bakau pantai air payau", "Tajuk pepohonan hutan pegunungan tinggi", "Gua-gua kapur bawah tanah", "Padang rumput terbuka dataran rendah"]'::jsonb,
    1,
    'Kanguru pohon beradaptasi dengan kaki depan yang kuat dan ekor panjang untuk memanjat dan melompat di antara ranting pohon hutan kabut Papua.'
),
(
    'Reptilia',
    'Kura-kura Moncong Babi (Carettochelys insculpta) memiliki hidung berdaging fleksibel menyerupai babi yang berguna untuk...',
    '["Snorkel mengambil udara saat tubuh terkubur di lumpur sungai", "Alat penyengat mangsa berdaya listrik", "Menggali lubang sarang di bebatuan keras", "Menghasilkan bau penolak buaya"]'::jsonb,
    0,
    'Moncong panjang seperti snorkel memungkinkan kura-kura ini bernapas di permukaan air tanpa harus memunculkan seluruh kepalanya ke atas.'
),
(
    'Amfibi',
    'Katak Terbang Jawa (Rhacophorus reinwardtii) dapat melayang meluncur dari satu dahan ke dahan lain menggunakan...',
    '["Selaput lebar di antara jari-jari kaki dan lipatan kulit paha", "Sayap berbulu halus di bagian dada", "Ekor panjang berotot kuat", "Kantung udara di bawah tenggorokan"]'::jsonb,
    0,
    'Selaput kaki yang sangat lebar bertindak sebagai parasut kecil sehingga katak pohon ini mampu meluncur di udara hingga jarak puluhan meter.'
),
(
    'Mamalia',
    'Banteng Jawa (Bos javanicus) memiliki penanda visual khas yang paling mudah dikenali di alam liar berupa...',
    '["Garis loreng hitam di punggung", "Tanduk yang selalu bercabang tiga", "Bercak putih bundar seperti cermin di bagian pantat", "Bulu leher lebat seperti surai singa"]'::jsonb,
    2,
    'Banteng Jawa memiliki warna putih kontras pada bagian pantat berbentuk oval (rump patch) serta kaos kaki putih di keempat kakinya.'
),
(
    'Mamalia',
    'Kuskus Beruang Sulawesi (Ailurops ursinus) adalah hewan marsupial kanopi hutan Sulawesi yang bergerak lambat dan beraktivitas saat...',
    '["Hanya saat fajar menyingsing", "Siang hari (diurnal) dengan memakan dedaunan muda", "Malam hari di dasar tanah", "Tidur selama 6 bulan di musim kemarau"]'::jsonb,
    1,
    'Berbeda dengan kuskus lain yang nokturnal, Kuskus Beruang adalah pemanjat pohon lambat yang aktif di siang hari memakan daun-daunan berkadar serat tinggi.'
),
(
    'Aves',
    'Cenderawasih Merah (Paradisaea rubra) yang memiliki sepasang bulu kawat ekor ganda melengkung merupakan satwa endemik pulau...',
    '["Waigeo dan Batanta di Kepulauan Raja Ampat", "Pulau Bali bagian barat", "Pulau Sumba di Nusa Tenggara", "Kepulauan Mentawai di barat Sumatera"]'::jsonb,
    0,
    'Cenderawasih Merah hanya ditemukan secara alami di hutan dataran rendah Pulau Waigeo dan Pulau Batanta, Raja Ampat, Papua Barat Daya.'
),
(
    'Reptilia',
    'Buaya Muara (Crocodylus porosus) dikenal sebagai reptil hidup terbesar di bumi yang memiliki adaptasi kelenjar garam khusus di lidahnya untuk...',
    '["Mendeteksi getaran gelombang sonar", "Mengeluarkan kelebihan garam sehingga bisa berenang jauh di laut lepas", "Menghasilkan bisa neurotoksin beracun", "Memecah cangkang penyu laut"]'::jsonb,
    1,
    'Kelenjar garam di lidah Buaya Muara memungkinkannya mengonsumsi air asin dan menjelajah samudra antar-pulau di kawasan Indo-Pasifik.'
),
(
    'Konservasi',
    'Taman Nasional Ujung Kulon yang terletak di provinsi Banten merupakan benteng pertahanan terakhir di dunia bagi satwa langka...',
    '["Gajah Kerdil Borneo", "Badak Jawa (Rhinoceros sondaicus)", "Harimau Bali", "Orangutan Tapanuli"]'::jsonb,
    1,
    'Taman Nasional Ujung Kulon adalah satu-satunya habitat alami yang tersisa di planet bumi bagi populasi Badak Jawa bercula satu.'
),
(
    'Reptilia',
    'Biawak Pohon Biru (Varanus macraei) adalah kadal pemanjat yang memiliki pola sisik biru pirus cerah dengan ekor prehensil, endemik pulau...',
    '["Pulau Batanta, Kepulauan Raja Ampat", "Pulau Komodo, NTT", "Pulau Nias, Sumatera", "Pulau Madura, Jawa Timur"]'::jsonb,
    0,
    'Varanus macraei ditemukan pertama kali pada tahun 2001 di Pulau Batanta, Papua Barat Daya, dan sangat mahir memanjat pohon menggunakan ekornya.'
),
(
    'Mamalia',
    'Gajah Sumatera (Elephas maximus sumatranus) memiliki ciri pembeda fisik dengan Gajah Afrika, di antaranya adalah...',
    '["Telinga berukuran lebih kecil dan memiliki dua tonjolan di dahi", "Tidak pernah memiliki gading pada jantan", "Memiliki bulu lebat di sekujur tubuh", "Memiliki dua lubang belalai terpisah"]'::jsonb,
    0,
    'Gajah Asia termasuk subspesies Sumatera memiliki telinga jauh lebih kecil dibanding Gajah Afrika dan punggung yang berbentuk melengkung cembung.'
),
(
    'Reptilia',
    'Penyu Belimbing (Dermochelys coriacea) adalah penyu laut terbesar di dunia yang memiliki keunikan fisik tempurung berupa...',
    '["Karapas bertanduk runcing seperti duri landak", "Karapas lunak menyerupai kulit tebal kenyal tanpa sisik keras", "Tempurung tembus pandang berbahan kalsium cair", "Tempurung berbentuk bola bulat sempurna"]'::jsonb,
    1,
    'Penyu Belimbing tidak memiliki tempurung bertulang keras bertumpuk sisik, melainkan karapas berkulit tebal dengan 7 lunas membujur.'
),
(
    'Konservasi',
    'Dalam konvensi perdagangan satwa liar internasional CITES, spesies yang masuk dalam daftar "Appendix I" memiliki arti...',
    '["Bebas diperjualbelikan antarnegara tanpa izin resmi", "Terancam punah dan dilarang keras untuk perdagangan komersial internasional", "Populasinya sangat melimpah dan boleh diburu", "Hanya berlaku untuk satwa peliharaan domestik"]'::jsonb,
    1,
    'Appendix I memuat spesies satwa liar yang terancam kepunahan sehingga seluruh transaksi komersial internasional dilarang keras.'
),
(
    'Mamalia',
    'Rusa Bawean (Axis kuhlii) adalah spesies rusa berpostur pendek dengan tanduk bercabang tiga yang hidup secara endemik terbatas di...',
    '["Pulau Bawean di perairan Laut Jawa", "Pulau Weh di ujung Aceh", "Pulau Karimunjawa di Jawa Tengah", "Pulau Maratua di Kalimantan Timur"]'::jsonb,
    0,
    'Rusa Bawean berstatus Kritis (CR) dan hanya hidup di kawasan perbukitan Pulau Bawean, sekitar 120 km sebelah utara Gresik, Jawa Timur.'
),
(
    'Reptilia',
    'Tokek dan cecak mampu menempel kuat di permukaan kaca atau dinding vertikal berkat jutaan rambut halus mikro di telapak kakinya yang memanfaatkan gaya...',
    '["Gaya magnetik statis bumi", "Gaya molekuler Van der Waals", "Lapisan lem cairan beracun", "Tekanan vakum penyedot udara"]'::jsonb,
    1,
    'Spatulae pada telapak kaki tokek menciptakan interaksi tarik-menarik molekuler (gaya Van der Waals) dengan permukaan benda tanpa memerlukan perekat cair.'
),
(
    'Konservasi',
    'Taman Nasional Lorentz yang merupakan taman nasional terluas di Asia Tenggara dan diakui sebagai Situs Warisan Dunia UNESCO terletak di kepulauan...',
    '["Sulawesi bagian selatan", "Sumatera bagian barat", "Kalimantan bagian timur", "Papua (membentang dari Puncak Carstensz hingga pesisir)"]'::jsonb,
    3,
    'Taman Nasional Lorentz di Papua memiliki gradasi ekosistem paling lengkap di Pasifik, dari gletser salju abadi puncak pegunungan hingga laut tropis.'
),
(
    'Aves',
    'Burung Maleo (Macrocephalon maleo) memiliki benjolan tanduk hitam keras di atas kepalanya yang diyakini para ahli berfungsi sebagai...',
    '["Sensor pendeteksi suhu pasir geotermal tempat bertelur", "Senjata mematikan untuk berburu serangga", "Kantung penyimpan makanan cadangan", "Alat penampung air hujan saat badai"]'::jsonb,
    0,
    'Benjolan (knob) di kepala Maleo diduga membantu merasakan panas bumi atau suhu pasir yang ideal untuk menetaskan telurnya.'
),
(
    'Mamalia',
    'Kukang Jawa (Nycticebus javanicus) adalah satu-satunya primata berbisa di dunia yang mengeluarkan cairan bisa berbahaya dari...',
    '["Kelenjar brakial di lipatan siku bagian dalam", "Kantung khusus di bawah lidah", "Ujung kuku jemari kaki belakang", "Kelenjar aroma di ekor"]'::jsonb,
    0,
    'Kukang menjilat kelenjar brakial di sikunya lalu mencampurnya dengan air liur untuk menghasilkan gigitan berbisa yang dapat memicu syok anafilaktik.'
),
(
    'Mamalia',
    'Lutung Jawa (Trachypithecus auratus) yang baru lahir memiliki keunikan fisik yang sangat mencolok dibanding induknya yang hitam pekat yaitu...',
    '["Bulu berwarna oranye keemasan terang benderang", "Tidak memiliki ekor sama sekali", "Memiliki cakar tajam seperti kucing", "Tubuh bercahaya di malam hari"]'::jsonb,
    0,
    'Bayi Lutung Jawa lahir dengan bulu berwarna oranye terang mencolok, yang memudahkan kelompok menjaga dan mengawasi bayi di antara rimbunnya hutan.'
),
(
    'Mamalia',
    'Tapir Asia (Tapirus indicus) memiliki corak warna dua warna (hitam dan pelana putih di punggung) yang berfungsi sebagai...',
    '["Kamuflase disrupsi visual pemecah siluet di malam hari", "Penyerap radiasi sinar matahari siang", "Penolak gigitan nyamuk hutan lebat", "Penanda hierarki kepemimpinan kawanan"]'::jsonb,
    0,
    'Pola hitam-putih kontras memecah siluet tubuh tapir di bawah sinar rembulan di hutan sehingga predator sulit mengenali bentuk tubuh utuhnya.'
),
(
    'Biota Laut',
    'Pari Manta Karang (Mobula alfredi) memiliki corak bintik hitam unik di bagian perutnya yang dimanfaatkan para peneliti untuk...',
    '["Identifikasi individu satwa menyerupai sidik jari manusia", "Menghasilkan sengatan listrik pertahanan diri", "Menarik perhatian mangsa ikan kecil", "Menentukan perkiraan umur tulang ikan"]'::jsonb,
    0,
    'Pola bintik di perut Pari Manta bersifat permanen dan unik untuk setiap individu, menjadi dasar metode foto-identifikasi populasi di alam.'
),
(
    'Mamalia',
    'Kucing Batu (Pardofelis marmorata) adalah kucing liar arboreal Indonesia yang memiliki adaptasi ekor sangat khas yaitu...',
    '["Sangat panjang dan tebal berotot untuk keseimbangan di dahan", "Sangat pendek seperti ekor kelinci", "Bergerigi tajam untuk mencengkeram ranting", "Berwarna putih polos tanpa corak"]'::jsonb,
    0,
    'Ekor Kucing Batu panjangnya menyamai panjang tubuhnya dan berfungsi sebagai penyeimbang sempurna saat melompat di tajuk pohon tinggi.'
),
(
    'Aves',
    'Burung Paok Bergaris (Pitta guajana) adalah burung endemik lantai hutan Jawa yang mencari makan berupa cacing dan serangga di antara...',
    '["Seresah tumpukan daun kering lantai hutan", "Tajuk puncak tertinggi pohon beringin", "Batang pohon pinus berlumut", "Bebatuan licin dasar air terjun"]'::jsonb,
    0,
    'Burung Paok banyak menghabiskan waktu melompat-lompat di lantai hutan yang lembap untuk membongkar seresah daun mencari invertebrata.'
),
(
    'Reptilia',
    'Tuntong Laut (Batagur borneoensis) jantan dewasa mengalami perubahan warna dramatis saat musim kawin berupa...',
    '["Warna kepala berubah putih terang dengan garis merah di antara mata", "Tempurung berubah hijau cerah bercahaya", "Leher memanjang dua kali ukuran semula", "Kaki berubah keemasan mengilap"]'::jsonb,
    0,
    'Perubahan warna kepala Tuntong jantan menjadi putih mencolok dengan corak merah terang berfungsi sebagai sinyal visual memikat betina.'
),
(
    'Biota Laut',
    'Hiu Paus (Rhincodon typus) yang sering dijumpai di perairan Gorontalo dan Papua adalah ikan terbesar di dunia yang memakan...',
    '["Plankton dan ikan kecil melalui tapis insang", "Bangkai mamalia paus besar", "Singa laut dan penyu dewasa", "Terumbu karang dan rumput laut"]'::jsonb,
    0,
    'Meskipun bertubuh raksasa hingga 12 meter lebih, Hiu Paus adalah pemakan saring (filter feeder) yang tidak memangsa satwa besar.'
),
(
    'Invertebrata',
    'Laba-laba Pelompat (Salticidae) memiliki sepasang mata utama depan berukuran sangat besar yang memungkinkannya...',
    '["Melihat warna dan memiliki persepsi kedalaman 3D yang sangat tajam", "Melihat dalam kegelapan total tanpa cahaya", "Menembakkan racun dari kejauhan", "Mendeteksi gelombang radio mangsa"]'::jsonb,
    0,
    'Laba-laba pelompat memiliki ketajaman visual terbaik di antara semua arthropoda untuk memperhitungkan jarak lompatan saat menerkam mangsa.'
),
(
    'Aves',
    'Burung Kacamata Wangi-wangi (Zosterops flavissimus) adalah burung endemik Kepulauan Wakatobi dengan ciri khas...',
    '["Lingkaran bulu putih halus melingkar di sekeliling matanya", "Ekor kaku melengkung berbentuk sabit", "Paruh bergerigi pemakan ikan kecil", "Jambul merah jambu di dahi"]'::jsonb,
    0,
    'Ciri utama genus Zosterops adalah cincin kacamata putih bersih yang mengelilingi bola mata.'
),
(
    'Aves',
    'Burung Kasuari di Papua selain dapat berlari kencang di daratan juga memiliki kemampuan fisik yang jarang diketahui yaitu...',
    '["Mampu berenang dengan lincah menyeberangi sungai lebar dan teluk laut", "Mampu terbang melayang rendah di malam hari", "Mampu memanjat pohon kelapa menggunakan sayap", "Bisa menggali terowongan bawah tanah"]'::jsonb,
    0,
    'Kasuari adalah perenang yang sangat andal dan sering terlihat menyeberangi sungai deras atau perairan pesisir di Papua.'
),
(
    'Reptilia',
    'Komodo (Varanus komodoensis) membunuh mangsa berukuran besar seperti kerbau dan rusa dengan mengandalkan gigitan yang mengandung...',
    '["Kelenjar bisa antikoagulan yang mencegah pembekuan darah", "Bisa hemotoksin penembus tulang", "Bisa neurotoksin penyengat saraf seketika", "Zat asam korosif penghancur kulit"]'::jsonb,
    0,
    'Riset modern membuktikan Komodo memiliki kelenjar bisa di rahang bawah yang mengeluarkan senyawa racun yang menurunkan tekanan darah dan mencegah darah membeku.'
),
(
    'Mamalia',
    'Gajah Kerdil Borneo (Elephas maximus borneensis) memiliki ciri morfologis khas dibanding gajah Asia lainnya yaitu...',
    '["Ekor sangat panjang yang menyentuh tanah dan gading lebih lurus", "Telinga dua kali lebih lebar dari gajah Afrika", "Memiliki dua punuk lemak di punggung", "Tidak pernah memiliki rambut sama sekali"]'::jsonb,
    0,
    'Gajah Kerdil Kalimantan memiliki postur lebih membulat (baby-faced), ekor panjang menjuntai hingga tanah, dan temperamen lebih jinak.'
),
(
    'Ikan',
    'Ikan Arwana Asia (Scleropages formosus) memiliki sepasang sungut (barbel) di ujung bibir bawahnya yang berguna untuk...',
    '["Mendeteksi riak getaran mangsa di permukaan air", "Menghasilkan sengatan listrik pertahanan", "Bernapas mengambil udara di musim kemarau", "Mengaitkan tubuh di celah bebatuan arus deras"]'::jsonb,
    0,
    'Sungut Arwana merupakan organ sensorik mekanoreseptor sensitif untuk mendeteksi serangga atau katak yang jatuh di permukaan air.'
),
(
    'Reptilia',
    'Kura-kura Hutan Sulawesi (Leucocephalon yuwonoi) jantan dewasa memiliki ciri unik pada kepalanya berupa...',
    '["Warna kepala memutih kontras menyerupai tengkorak", "Tanduk bercabang tiga di atas hidung", "Kantung kulit yang bisa mengembang di dagu", "Mata merah menyala di kegelapan"]'::jsonb,
    0,
    'Jantan dewasa spesies langka ini memiliki kepala berwarna kuning pucat keputihan yang sangat kontras dengan leher dan tubuhnya.'
),
(
    'Invertebrata',
    'Kupu-kupu Sayap Burung Peri (Ornithoptera chimaera) adalah spesies kupu-kupu raksasa dengan sayap hijau keemasan yang hidup di dataran tinggi pulau...',
    '["Papua", "Jawa", "Sumatera", "Nusa Tenggara"]'::jsonb,
    0,
    'Genus Ornithoptera (kupu-kupu sayap burung) adalah serangga megah yang hidup di hutan pegunungan Pulau Papua dan dilindungi ketat.'
),
(
    'Mamalia',
    'Siamang (Symphalangus syndactylus) di hutan Sumatera memiliki kantung tenggorokan besar (gular sac) yang berfungsi untuk...',
    '["Menghasilkan resonansi suara panggilan duet yang terdengar hingga 2 km", "Menyimpan cadangan buah dan air", "Menghangatkan tubuh saat suhu dingin", "Mengembangkan tubuh untuk menakut-nakuti macan"]'::jsonb,
    0,
    'Kantung gular dapat mengembang seukuran kepala siamang untuk memperkeras resonansi suara panggilan teritorial melintasi kanopi hutan.'
),
(
    'Mamalia',
    'Pesut Mahakam memiliki bentuk kepala yang berbeda dari lumba-lumba laut pada umumnya, yaitu...',
    '["Membulat tumpul tanpa moncong paruh yang memanjang", "Moncong sangat panjang menyerupai paruh burung", "Memiliki cula tajam di atas dahi", "Pipih melebar menyerupai ikan pari"]'::jsonb,
    0,
    'Pesut Mahakam (Orcaella brevirostris) memiliki dahi membulat tinggi (melon) dan tidak memiliki moncong moncong panjang khas lumba-lumba laut.'
),
(
    'Konservasi',
    'Taman Nasional Komodo yang dibentuk pada tahun 1980 melindungi habitat alami biawak purba Komodo di kepulauan...',
    '["Pulau Komodo, Rinca, Padar, Gili Motang, dan Nusa Kode", "Kepulauan Mentawai dan Nias", "Kepulauan Karimunjawa dan Bawean", "Kepulauan Derawan dan Maratua"]'::jsonb,
    0,
    'Taman Nasional Komodo mencakup gugusan tiga pulau besar (Komodo, Rinca, Padar) serta puluhan pulau kecil di Selat Sape, NTT.'
),
(
    'Reptilia',
    'Bunglon Sisir (Gonocephalus chamaeleontinus) mengandalkan pertahanan utama dari ancaman predator hutan berupa...',
    '["Kamuflase mimikri menyatu sempurna dengan lumut dan kulit kayu", "Bisa gigitan neurotoksik mematikan", "Kemampuan memutuskan ekor berulang kali", "Lompatan jauh di atas permukaan air"]'::jsonb,
    0,
    'Kadal bermahkota sisir ini memiliki pola warna dan tekstur kulit kasar yang meniru lumut dan kulit pohon hutan hujan tropis Jawa-Sumatera.'
)
ON CONFLICT (question) DO NOTHING;

