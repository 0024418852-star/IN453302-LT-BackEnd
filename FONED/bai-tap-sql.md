# Bài tập SQL: JOIN, GROUP BY và Transaction

- **Họ và tên:** Võ Nguyễn Đức Thiện
- **Email:** vonguyenducthien2006@gmail.com
- **MSSV:** 0024418852
- **Lớp:** DHCNNTT24B-CS
- **Ngày thực hiện:** 21/10/2026
- **Hệ quản trị CSDL:** PostgreSQL (chạy bằng DBeaver / pgAdmin / `psql`)

---

## 0. Chuẩn bị: tạo bảng và dữ liệu mẫu

### Sơ đồ quan hệ

```
members (id, full_name, email)
    └──< registrations (id, member_id, course_id) >──┘
                                                   courses (id, title)
```

`registrations` là bảng trung gian: một thành viên đăng ký nhiều khóa, một khóa có nhiều thành viên (quan hệ nhiều-nhiều).

### Script tạo bảng

```sql
DROP TABLE IF EXISTS registrations;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS members;

CREATE TABLE members (
    id        SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE courses (
    id    SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE registrations (
    id        SERIAL PRIMARY KEY,
    member_id INT NOT NULL REFERENCES members(id),
    course_id INT NOT NULL REFERENCES courses(id),
    UNIQUE (member_id, course_id)          -- không cho đăng ký trùng
);
```

### Dữ liệu mẫu

```sql
INSERT INTO members (full_name, email) VALUES
 ('Nguyễn An', 'an@example.com'),
 ('Lê Chi',    'chi@example.com'),
 ('Trần Bình', 'binh@example.com'),
 ('Phạm Dung', 'dung@example.com');

INSERT INTO courses (title) VALUES
 ('Lập trình Web'),
 ('Cơ sở dữ liệu'),
 ('Mạng máy tính'),
 ('Trí tuệ nhân tạo');

INSERT INTO registrations (member_id, course_id) VALUES
 (1, 1), (1, 2), (1, 3),    -- Nguyễn An: Web, CSDL, Mạng
 (2, 1),                    -- Lê Chi: Web
 (3, 1), (3, 2);            -- Trần Bình: Web, CSDL
```

---

## Bài 1: Liệt kê tên các khóa học mà Nguyễn An đã đăng ký

**Yêu cầu:** dùng `JOIN` kết nối 3 bảng `members`, `registrations`, `courses` và lọc theo tên thành viên.

**Cách làm:**
1. Bắt đầu từ `members`, lọc `full_name = 'Nguyễn An'`.
2. `JOIN registrations` qua `member_id` để lấy các phiếu đăng ký của An.
3. `JOIN courses` qua `course_id` để lấy tên khóa.
4. Dùng `DISTINCT` để không lặp tên khóa nếu có phiếu trùng.

```sql
SELECT DISTINCT c.title
FROM members m
JOIN registrations r ON r.member_id = m.id
JOIN courses c       ON c.id = r.course_id
WHERE m.full_name = 'Nguyễn An'
ORDER BY c.title;
```

**Kết quả:**

| title |
|---|
| Cơ sở dữ liệu |
| Lập trình Web |
| Mạng máy tính |

---

## Bài 2: Đếm số thành viên của mỗi khóa, khóa nhiều người nhất đứng đầu

**Yêu cầu:** `GROUP BY` theo khóa, `COUNT()` số người đăng ký, `ORDER BY ... DESC`; dùng `LEFT JOIN` để khóa chưa có người đăng ký vẫn xuất hiện.

**Cách làm:**
1. Lấy `courses` làm bảng gốc, `LEFT JOIN registrations` để giữ cả khóa chưa có ai.
2. `GROUP BY c.id, c.title`.
3. Đếm bằng `COUNT(r.id)`. Không dùng `COUNT(*)` vì nó đếm cả dòng rỗng do `LEFT JOIN`, làm khóa không có ai bị tính là 1.
4. Sắp xếp giảm dần theo số lượng, thêm `c.title` để thứ tự ổn định khi bằng nhau.

```sql
SELECT c.id,
       c.title,
       COUNT(r.id) AS so_luong_thanh_vien
FROM courses c
LEFT JOIN registrations r ON r.course_id = c.id
GROUP BY c.id, c.title
ORDER BY so_luong_thanh_vien DESC, c.title;
```

**Kết quả (trước Bài 3):**

| id | title | so_luong_thanh_vien |
|---|---|---|
| 1 | Lập trình Web | 3 |
| 2 | Cơ sở dữ liệu | 2 |
| 3 | Mạng máy tính | 1 |
| 4 | Trí tuệ nhân tạo | 0 |

Khóa "Trí tuệ nhân tạo" chưa có ai nhưng vẫn hiện với số 0 nhờ `LEFT JOIN`.

---

## Bài 3: Thêm / chuyển Lê Chi vào khóa "Cơ sở dữ liệu" bằng Transaction

**Yêu cầu:** thao tác ghi dữ liệu phải nằm trong giao dịch `BEGIN ... COMMIT` để đảm bảo tính nguyên tử: hoặc thực hiện đủ, hoặc không thay đổi gì.

### 3a. Thêm đăng ký mới

```sql
BEGIN;

INSERT INTO registrations (member_id, course_id)
SELECT m.id, c.id
FROM members m
CROSS JOIN courses c
WHERE m.full_name = 'Lê Chi'
  AND c.title = 'Cơ sở dữ liệu'
  AND NOT EXISTS (
      SELECT 1 FROM registrations r
      WHERE r.member_id = m.id AND r.course_id = c.id
  );

COMMIT;
```

**Giải thích:**
- Lấy `id` của Lê Chi và của khóa "Cơ sở dữ liệu" ngay trong câu `INSERT ... SELECT`.
- `NOT EXISTS` ngăn đăng ký trùng; chạy lại lệnh này không chèn thêm dòng nào (`INSERT 0 0`).
- Nếu tên thành viên hoặc khóa học không tồn tại, câu lệnh chèn 0 dòng, không chèn `NULL` và không gây lỗi.

**Kết quả khi chạy:** `BEGIN`, `INSERT 0 1`, `COMMIT`.

**Kiểm tra lại:** Lê Chi giờ có 2 khóa (Cơ sở dữ liệu, Lập trình Web), và Bài 2 cho kết quả mới:

| id | title | so_luong_thanh_vien |
|---|---|---|
| 2 | Cơ sở dữ liệu | 3 |
| 1 | Lập trình Web | 3 |
| 3 | Mạng máy tính | 1 |
| 4 | Trí tuệ nhân tạo | 0 |

### 3b. Chuyển từ khóa cũ sang khóa "Cơ sở dữ liệu"

"Chuyển" gồm hai bước (hủy phiếu cũ, tạo phiếu mới), nên transaction là bắt buộc: không để xảy ra tình huống đã hủy khóa cũ mà chưa kịp đăng ký khóa mới.

```sql
BEGIN;

-- Bước 1: hủy phiếu ở khóa cũ (ví dụ "Lập trình Web", đổi theo đề)
DELETE FROM registrations
WHERE member_id = (SELECT id FROM members WHERE full_name = 'Lê Chi')
  AND course_id = (SELECT id FROM courses WHERE title = 'Lập trình Web');

-- Bước 2: đăng ký khóa "Cơ sở dữ liệu"
INSERT INTO registrations (member_id, course_id)
SELECT m.id, c.id
FROM members m
CROSS JOIN courses c
WHERE m.full_name = 'Lê Chi'
  AND c.title = 'Cơ sở dữ liệu'
  AND NOT EXISTS (
      SELECT 1 FROM registrations r
      WHERE r.member_id = m.id AND r.course_id = c.id
  );

COMMIT;
```

**Kết quả khi chạy:** `BEGIN`, `DELETE 1`, `INSERT 0 1`, `COMMIT`. Lê Chi chỉ còn khóa "Cơ sở dữ liệu".

### Hoàn tác khi có lỗi

Nếu giữa chừng có lỗi hoặc muốn hủy, chạy `ROLLBACK;` thay cho `COMMIT;`. Ví dụ minh họa:

```sql
BEGIN;
DELETE FROM registrations;                    -- DELETE 6
SELECT COUNT(*) FROM registrations;           -- 0 (trong giao dịch)
ROLLBACK;
SELECT COUNT(*) FROM registrations;           -- 6 (dữ liệu được khôi phục)
```

---

## Tổng kết kiến thức

| Nội dung | Điểm cần nhớ |
|---|---|
| `JOIN` | Nối bảng qua khóa ngoại; chỉ giữ các dòng khớp ở cả hai phía |
| `LEFT JOIN` | Giữ mọi dòng bảng bên trái, kể cả khi bên phải không có dữ liệu |
| `GROUP BY` + `COUNT(cột)` | Gom nhóm và đếm; `COUNT(cột)` bỏ qua `NULL`, `COUNT(*)` thì không |
| `ORDER BY ... DESC` | Sắp xếp giảm dần |
| Transaction | `BEGIN` → các lệnh ghi → `COMMIT` (hoặc `ROLLBACK`); đảm bảo tính nguyên tử |
| `NOT EXISTS` | Chặn chèn trùng, giúp lệnh chạy lại an toàn |
