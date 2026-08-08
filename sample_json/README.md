# sample_json — dữ liệu mẫu

Fixture để đọc và để test, không phải file app đọc lúc chạy —
`DevSeedService` vẫn là thứ seed máy dev.

```
sample_json/
  local/      dữ liệu trên máy — 7 bảng Drift (SQLite), schema v9
  firebase/   dữ liệu trên Firestore — 7 collection + payload đã giải mã
```

Hai bên **cùng một người dùng và cùng một tập id**, nên đọc chéo được: một
attack dưới máy và document đã mã hoá của nó trên server có chung `id`.

Điểm khác nhau đáng chú ý, và cũng là điểm chính của việc tách hai thư mục:

- **Máy giữ dữ liệu dạng rõ, server chỉ giữ ciphertext.** Toàn bộ intensity,
  ghi chú, tên thuốc nằm trong `payload` base64; server chỉ đọc được `userId`
  và `updatedAt`.
- **Server không có mọi thứ máy có.** `export_records` và `sync_tombstones`
  không bao giờ lên server, và dòng nào `syncedRevision: null` thì cũng chưa
  lên.
- **Máy không có mọi thứ server có.** `users/{uid}`, `sync_keys/{uid}` và
  `app_updates` chỉ tồn tại trên Firestore.
- **Xoá thì hai bên khác hẳn nhau.** Dưới máy dòng bị xoá thật, để lại một
  tombstone chỉ có id; trên server document vẫn còn nhưng `deleted: true` và
  ciphertext bị xoá trắng.

Chi tiết từng file, quy ước ngày giờ/enum, và danh sách các ca biên: đọc
`local/README.md` và `firebase/README.md`.
