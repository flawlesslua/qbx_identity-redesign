# Spesifikasi MLO untuk `kios`

Dokumen ini untuk pembuat MLO (CodeWalker, Blender + Sollumz, atau 3ds Max). Intinya: **MLO hanya
berupa cangkang kosong.** Semua rak, kulkas, dan mesin kasir di-spawn oleh script, supaya bisa
dipindah di renovation mode dan produknya bisa diambil satu per satu.

## 1. Denah

| Ruang | Ukuran saran | Catatan |
| --- | --- | --- |
| Area jual | ±14 × 12 m | Lantai rata di **satu ketinggian Z**, tanpa tangga atau undakan |
| Meja kasir | ±4 m, menempel dinding samping pintu | Boleh statis (bagian dari MLO), tinggi permukaan ±0,95 m |
| Gudang belakang | ±4 × 6 m | Pintu ke area jual. Untuk kardus stok (tahap restock) |
| Pintu masuk | Pintu kaca ganda | Area 2 × 2 m di depan pintu harus tetap kosong |

- Plafon minimal 3 m.
- Dinding lurus dan tegak (tanpa lengkungan), supaya rak dinding bisa menempel rapi.
- Jangan pasang rak atau produk statis di area jual. Dekorasi dinding (poster, neon, jam) boleh.

## 2. Wajib

- **Rooms & portals** yang benar (area jual, gudang, meja kasir boleh satu room dengan area jual).
- **Collision (.ybn)** untuk lantai, dinding, plafon, meja kasir, dan pintu.
- **Timecycle** dalam ruangan yang terang (gaya minimarket). Lampu plafon panel putih.
- **Satu file .ymap** untuk menempatkan MLO di lokasi pilihan.
- Material lantai yang mengeluarkan suara langkah (tile/keramik).

## 3. Entity set untuk lantai dan dinding

Kustomisasi interior (tahap 7) bekerja dengan menyalakan satu entity set lantai dan satu entity set
dinding. Setiap varian dibuat sebagai entity set terpisah yang berisi mesh lantai/dinding dengan
material berbeda. Nama harus persis seperti di bawah (boleh ditambah):

**Lantai** (`kios_floor_<id>`)

| Entity set | Kategori | Keterangan |
| --- | --- | --- |
| `kios_floor_classic` | Classic | Tile 24/7 hijau-putih (default) |
| `kios_floor_basalt` | Plain | Abu gelap polos |
| `kios_floor_darkgrey` | Plain | Abu tua |
| `kios_floor_marble` | Classic | Marmer putih |
| `kios_floor_granite` | Classic | Granit hitam |
| `kios_floor_terrazzo` | Classic | Terrazzo |
| `kios_floor_wood` | Classic | Kayu |
| `kios_floor_checker` | Checker | Kotak hitam-putih |
| `kios_floor_diamond` | Diamond | Pola wajik abu-putih |
| `kios_floor_star` | Encaustic | Tegel bintang biru-kuning |
| `kios_floor_flower` | Encaustic | Tegel bunga terakota |

**Dinding** (`kios_wall_<id>`)

| Entity set | Keterangan |
| --- | --- |
| `kios_wall_classic` | Putih dengan aksen merah 24/7 (default) |
| `kios_wall_stripe` | Putih dengan garis merah-oranye |
| `kios_wall_greendado` | Putih dengan dado (panel bawah) hijau |
| `kios_wall_red` | Merah penuh |
| `kios_wall_white` | Putih polos |
| `kios_wall_subway` | Subway tile putih |
| `kios_wall_brick` | Bata dicat |
| `kios_wall_wood` | Panel kayu bawah |
| `kios_wall_greyorange` | Abu dengan aksen oranye |
| `kios_wall_navy` | Putih dengan garis navy |

Aturan entity set:
- Hanya satu entity set lantai dan satu entity set dinding yang menyala sekaligus. Script yang
  mengatur ini (`ActivateInteriorEntitySet` / `DeactivateInteriorEntitySet`).
- Collision lantai dan dinding **tidak** ikut di entity set (tetap di MLO utama), supaya player
  tidak jatuh saat entity set diganti.
- Mesh varian diletakkan sedikit di atas collision (±1 cm) supaya tidak z-fighting.

## 4. Prop furnitur kosong (disarankan)

Rak vanilla 24/7 sudah menyatu dengan produknya, jadi tidak cocok. Sertakan prop terpisah (.ydr + .ytyp)
untuk furnitur kosong berikut. Origin model di **tengah bawah**, dan sisi depan menghadap **+Y**.

| Nama prop saran | Ukuran ± | Keterangan |
| --- | --- | --- |
| `kios_shelf_double` | 1,6 × 0,7 × 1,7 m | Rak tengah dua sisi, 4 tingkat |
| `kios_shelf_wall` | 1,6 × 0,45 × 1,9 m | Rak dinding satu sisi, 4 tingkat |
| `kios_fridge` | 0,9 × 0,7 × 2,0 m | Kulkas minuman, **pintu kaca sebagai prop terpisah** (`kios_fridge_door`, origin di engsel) |
| `kios_candy_stand` | 0,6 × 0,4 × 0,6 m | Stand permen kecil untuk di atas meja kasir |
| `kios_storage_rack` | 1,8 × 0,6 × 2,0 m | Rak gudang untuk kardus |

Setelah prop jadi, ganti `model` di `config/furniture.lua` dan atur spot dengan `/kios spots`.

## 5. Yang perlu dikirim balik

1. Folder resource stream (misalnya `kios_mlo/stream/...` + `fxmanifest.lua`).
2. Koordinat pusat area jual dan heading MLO (untuk `zone` di `config/shops.lua`).
3. Nama interior (archetype MLO) untuk dipakai `GetInteriorAtCoordsWithType`.
4. Daftar entity set yang benar-benar dibuat.
