# Bài tập 2.2: RESTful API & JSON API

- **Họ và tên:** Võ Nguyễn Đức Thiện
- **Email:** vonguyenducthien2006@gmail.com
- **MSSV:** 0024418852
- **Lớp:** DHCNNTT24B-CS
- **Ngày thực hiện:** 21/10/2026

---

## Bộ bài tập 2.2.1 (Thiết kế RESTful API)

| Yêu cầu                                      | Method & URI                                   | Mã trạng thái                         |
| -------------------------------------------- | ---------------------------------------------- | ------------------------------------- |
| Hủy phiếu đăng ký số 42                      | `DELETE /api/v1/registrations/42`              | `204 No Content`                      |
| Lấy danh sách khóa còn chỗ, sắp xếp theo tên | `GET /api/v1/courses?hasSeats=true&sort=title` | `200 OK`                              |
| Hủy phiếu không tồn tại                      | `DELETE /api/v1/registrations/{id}`            | `404 Not Found` (kèm Problem Details) |

## Bộ bài tập 2.2.2 (JSON API tạo thành viên)

### Request

- **Method & URI:** `POST /api/v1/members`
- **Header:** `Content-Type: application/json`

```json
{
  "fullName": "Nguyễn Văn A",
  "email": "nguyenvana@example.com"
}
```

### Response thành công

- **Mã trạng thái:** `201 Created`
- **Header:** `Location: /api/v1/members/101`

```json
{
  "id": 101,
  "fullName": "Nguyễn Văn A",
  "email": "nguyenvana@example.com"
}
```

### Response lỗi trùng email (Problem Details, RFC 9457)

- **Mã trạng thái:** `409 Conflict`
- **Header:** `Content-Type: application/problem+json`

```json
{
  "type": "https://eduhub.example/errors/email-already-exists",
  "title": "Email đã tồn tại",
  "status": 409,
  "detail": "Email 'nguyenvana@example.com' đã được sử dụng bởi thành viên khác.",
  "instance": "/api/v1/members"
}
```
