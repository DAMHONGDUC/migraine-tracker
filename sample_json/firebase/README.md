# firebase/ — dữ liệu trên Firestore

Không phải bản sao của `local/` theo từng cột. Firestore chỉ giữ **bản mã hoá**
của bản ghi sức khoẻ, cộng một document cấu hình cho mỗi user.

| File | Đường dẫn | Ai đọc/ghi được |
| --- | --- | --- |
| `users.json` | `users/{uid}` | chỉ chủ nhân; `premium` chỉ webhook RevenueCat ghi |
| `attacks.json` | `attacks/{docId}` | lọc theo `userId` |
| `medications.json` | `medications/{docId}` | lọc theo `userId` |
| `medication_reminders.json` | `medication_reminders/{docId}` | lọc theo `userId` |
| `notifications.json` | `notifications/{docId}` | lọc theo `userId` |
| `sync_keys.json` | `sync_keys/{uid}` | **không client nào** — chỉ callable `getSyncKey` qua Admin SDK |
| `app_updates.json` | `app_updates/{autoId}` | ai cũng đọc được, không ai ghi được |

Thêm hai file không phải collection:

- `payload_plaintext.json` — **nội dung thật bên trong `payload`** sau khi giải
  mã, khoá theo `<collection>/<docId>`. Đây là thứ `AttackPayloadCodec` và ba
  codec còn lại encode; không có trên server ở dạng này.
- `push_pressure_alert.json` — message FCM mà cron `functions/src/index.ts` gửi.

`all_collections.json` gộp 7 collection, sinh ra từ các file kia.

## Quy ước

- **`__id__` là document id, không phải một field.** Trong Firestore nó là tên
  document; ở đây phải để trong object mới đọc được.
- **Ngày giờ để ISO-8601 UTC.** Trên Firestore chúng là `Timestamp` — riêng
  `app_updates.create_date` **bắt buộc** phải là `timestamp`, không được là
  chuỗi: Firestore sắp xếp theo kiểu trước, nên một record lưu dạng chuỗi sẽ
  nằm dưới mọi timestamp và `orderBy(create_date, desc).limit(1)` không bao giờ
  thấy nó.
- **Cấu trúc phẳng, không phải subcollection.** `attacks/{docId}` chứ không
  `users/{uid}/attacks/{docId}`, nên `userId` là **toàn bộ ranh giới** giữa dữ
  liệu hai người: rules kiểm nó ở mọi thao tác, và **mọi query bắt buộc lọc
  theo nó** (`OwnedCollection` là chỗ duy nhất dựng reference tới các
  collection này).
- **`payload` / `nonce` / `mac` đều base64.** Ở các file mẫu này chúng là **byte
  ngẫu nhiên đúng độ dài**, không giải mã ra được — nonce 12 byte, mac 16 byte,
  ciphertext dài bằng plaintext. Muốn xem nội dung thì đọc
  `payload_plaintext.json`.
- **Ba field đó được miễn index** (`fieldOverrides` trong `firestore.indexes.json`):
  chỉ `userId` và `updatedAt` từng được query.
- **Query pull cần composite index `userId` + `updatedAt` cho từng collection.**

## Những ca cố tình đưa vào

- `users[0]` — user đã đăng nhập: đủ field tài khoản, đăng ký alert, `premium:
  true`, và `lastAlertAt`/`lastAlertEventId` do cron ghi.
- `users[1]` — user ẩn danh: **chỉ có** geohash5, fcmToken, alertThreshold, tz,
  premium. Không có tên, email, và không có bản ghi sức khoẻ nào (hard rule 1).
- `users[2]` — chưa cấp quyền vị trí / thông báo: không geohash, không token,
  nên cron bỏ qua.
- Mỗi collection đồng bộ đều có **một document `deleted: true`** — tombstone đã
  được đẩy lên: `payload`/`nonce`/`mac` bị xoá trắng, chỉ còn `updatedAt` để
  bên nào mới hơn thì thắng. Xoá thuốc thì reminder của nó cũng phải có
  tombstone riêng, vì Firestore không có cascade.
- **Server chỉ giữ những dòng đã được xác nhận.** Attack thứ 2 và thứ 4 trong
  `local/attacks.json` có `syncedRevision: null` nên không xuất hiện ở đây; còn
  attack thứ 5 ở đây là bản `revision 4`, cũ hơn bản `revision 5` dưới máy.
- `app_updates` — một record hiện tại (`enable_force_update: false`) và một
  record cũ. Mỗi lần phát hành thì **tạo document mới**, không sửa document cũ.

## Cảnh báo

`sync_keys.json` là **placeholder**, không phải khoá thật và không giải mã được
gì. Khoá thật do server giữ, nghĩa là **sync được mã hoá nhưng KHÔNG phải
end-to-end** — hạ tầng Google giải mã được. Đừng viết copy nào ngụ ý ngược lại.
