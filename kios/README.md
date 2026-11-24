# kios

Script toko fisik untuk FiveM. Produk adalah prop 3D satu per satu di rak, diambil dengan tangan,
dibawa ke kasir, lalu dibayar. Tidak ada menu belanja.

> **Status: Tahap 1 (belum dites di dalam game).** Kode sudah lolos cek sintaks dan UI sudah dicek
> di browser, tapi belum pernah dijalankan di server FiveM. Tolong tes dan laporkan bug-nya.

## Fitur tahap 1

- **Rak & spot produk.** Setiap furnitur (rak, kulkas, stand permen) punya spot. Setiap spot berisi
  satu jenis produk dengan jumlah stok, dan propnya ditumpuk sesuai stok.
- **Bidik untuk berinteraksi.** Titik putih di setiap spot. Spot yang dibidik memunculkan label
  melayang (nama, jumlah, harga) dan tombol aksi: `[E] AMBIL`, `[G] TARUH`.
- **Barang dipegang di tangan.** Maksimal `Config.maxCarry` barang. Prop terlihat oleh semua
  player (lewat state bag, jadi aman dengan entity lockdown). Barang **belum** masuk inventory.
- **Self-checkout.** `[E] BAYAR` di kasir menaruh barang di meja, lalu animasi memindai muncul
  (bunyi beep per barang). Struk TAGIHAN tampil, bayar dengan `[E] TUNAI` / `[G] KARTU`, muncul
  stempel LUNAS, dan kantong belanja muncul di meja. `[E] AMBIL KANTONG` memasukkan semua barang
  ke ox_inventory.
- **Keluar tanpa bayar.** Barang menjadi milik pembeli (`Config.theft.mode = 'keep'`), dicatat
  sebagai `theft`, dan memicu event `kios:theft` untuk script dispatch polisi.
- **Semua framework.** Qbox, QBCore, ESX, ox_core (eksperimental), ND_Core, atau standalone.
- **Server-authoritative.** Stok, harga, total, dan pembayaran dihitung dan divalidasi di server.
- **Tool admin.** Pasang/hapus furnitur, editor spot, menu stok.
- **Bahasa:** English & Indonesia (`setr ox:locale id`).

## Kebutuhan

- OneSync
- [ox_lib](https://github.com/overextended/ox_lib), [oxmysql](https://github.com/overextended/oxmysql),
  [ox_inventory](https://github.com/overextended/ox_inventory)
- Salah satu framework di atas (opsional)

## Instalasi

1. Salin folder `kios` ke folder `resources` server.
2. Tambahkan item dari `install/ox_inventory_items.lua` ke `ox_inventory/data/items.lua`.
3. Di `server.cfg`, setelah framework dan ox_inventory:
   ```
   ensure kios
   ```
4. Tabel database (`kios_shops`, `kios_furniture`, `kios_transactions`) dibuat otomatis saat start.

Framework dideteksi otomatis. Untuk memaksa framework tertentu: `setr kios:framework "qbx"`
(`qbx | qb | esx | ox | nd`).

## Tes cepat (24/7 Innocence Blvd, interior vanilla)

Semua perintah admin butuh ACE `group.admin`.

1. Masuk ke 24/7 di Innocence Blvd (contoh toko di `config/shops.lua`).
2. `/kios place shelf_double`: bidik lantai, putar dengan scroll (tahan Shift untuk halus),
   tekan `E` untuk memasang. Garis hijau berarti boleh dipasang, merah berarti di luar toko.
3. `/kios place register_self`: pasang mesin kasir di atas meja kasir.
4. `/kios stock`: bidik spot (muncul `? tempat`), tekan `Enter`, pilih produk. Spotnya langsung
   terisi penuh. Atau pakai `/kios fill` untuk mengisi penuh semua spot yang sudah punya produk.
5. Ketik `/kios stock` lagi untuk mematikan mode stok, lalu belanja seperti pembeli biasa.

Perintah lain: `/kios remove` (bidik furnitur), `/kios spots` (editor spot), `/kios types`
(daftar tipe furnitur).

## Mengatur posisi spot

Model furnitur di `config/furniture.lua` masih placeholder vanilla, jadi posisi spot hasil
`Kios.grid(...)` mungkin tidak pas dengan raknya.

1. Pasang furniturnya, bidik, lalu jalankan `/kios spots`.
2. Bidik permukaan rak dan tekan `E` untuk menambah spot (produk menghadap ke arahmu, dibulatkan
   ke 90°, tahan Shift untuk sudut bebas). `Backspace` membatalkan spot terakhir.
3. Tekan `Enter`. Teks `spots = { ... }` disalin ke clipboard dan dicetak di F8.
4. Tempel ke furnitur yang bersangkutan di `config/furniture.lua`, lalu restart resource.

Model yang tidak ada di file game diganti `Config.fallbackModel` dan muncul peringatan di F8.
Cek F8 saat tes pertama dan ganti nama model yang hilang.

## Config penting

| File | Isi |
| --- | --- |
| `config/shared.lua` | tombol, jarak bidik, `maxCarry`, aturan pencurian, waktu scan, metode bayar |
| `config/products.lua` | produk: label, item ox_inventory, harga, model, kapasitas spot, tumpukan prop |
| `config/furniture.lua` | furnitur: model, spot, data kasir (slot meja, posisi kantong, panel struk) |
| `config/shops.lua` | lokasi toko: zona, blip, model vanilla yang disembunyikan |

## Hook untuk script lain

```lua
-- server: seseorang keluar membawa barang yang belum dibayar
AddEventHandler('kios:theft', function(shopId, src, items, value)
    -- kirim alert ke polisi, dsb.
end)
```

## Struktur

```
kios/
├── bridge/server/   adaptor framework (qbx, qb, esx, ox, nd)
├── client/          prop, bidik, barang di tangan, kasir, tool admin
├── config/          semua pengaturan
├── docs/            spesifikasi MLO
├── install/         item ox_inventory
├── locales/         en.json, id.json
├── server/          database, state toko, keranjang, kasir, admin
├── shared/          util (offset lokal ⇄ dunia, zona, grid spot)
└── web/             UI (React + Vite + TypeScript); hasil build di web/dist
```

Mengubah UI: `cd web && npm install && npm run build`. Preview di browser: `npm run dev`, lalu buka
`http://localhost:5173/?demo=pay` (`scanning`, `pay`, atau `paid`).

## Rencana tahap berikutnya

2. ~~Self-checkout dan kantong belanja~~ (sudah masuk tahap 1)
3. Kasir yang dijaga karyawan (Scan → Charge → Bag → Hand over) dan sistem tip
4. Restock dengan kardus dari gudang (`? tempat` → ASSIGN, RESTOCK)
5. Manajemen pemilik: beli toko, karyawan, harga, saldo, menu supplier
6. Renovation mode (geser furnitur dengan kamera atas, batas furnitur, cek lorong)
7. Kustomisasi interior lantai/dinding (entity set MLO)
8. Pintu kulkas yang bisa dibuka
