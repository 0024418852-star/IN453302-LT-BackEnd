# Phần 2.4: Bảo mật API

- **Họ và tên:** Võ Nguyễn Đức Thiện 
- **Email:** vonguyenducthien2006@gmail.com
- **MSSV:** 0024418852
- **Lớp:** DHCNNTT24B-CS
- **Ngày thực hiện:** 21/10/2026

---


| Chủ đề | Nguy cơ | Cách phòng chống |
|---|---|---|
| **CORS** | Trang web lạ gọi API từ trình duyệt người dùng | Server chỉ cho phép origin tin cậy; trình duyệt gửi preflight `OPTIONS` với request không đơn giản (`PUT`, `DELETE`, header `Authorization`, `Content-Type: application/json`) |
| **SSL/TLS, HTTPS** | Bị nghe lén hoặc sửa dữ liệu trên đường truyền | Mã hóa toàn bộ dữ liệu qua bắt tay TLS, chuyển hướng HTTP sang HTTPS |
| **SQL Injection** | Chèn câu lệnh SQL qua đầu vào | Luôn tham số hóa truy vấn (EF Core, Dapper `@param`), không nối chuỗi SQL |
| **XSS** | Chèn script độc vào trang hiển thị | Encode dữ liệu hiển thị, header `Content-Security-Policy` (CSP), cookie `HttpOnly` |
| **Mật khẩu** | Lộ CSDL thì lộ mật khẩu | Băm bằng hàm chậm (Argon2id, bcrypt); salt riêng từng tài khoản, nằm sẵn trong chuỗi hash |
| **Rate limiting & tường lửa** | Gọi dồn dập, dò mật khẩu, quá tải | Giới hạn số lượt gọi/phút (trả `429 Too Many Requests`); ẩn cổng CSDL/Redis khỏi Internet |

### Code minh họa

```csharp
// SQL Injection: SAI (nối chuỗi)
var bad = $"SELECT * FROM Members WHERE Email = '{email}'";

// ĐÚNG (tham số hóa)
var good = "SELECT * FROM Members WHERE Email = @Email";
var member = await conn.QueryFirstOrDefaultAsync<Member>(good, new { Email = email });
```

```csharp
// CORS + Rate limiting + HTTPS (Program.cs)
builder.Services.AddCors(o => o.AddPolicy("web", p =>
    p.WithOrigins("https://eduhub.example").AllowAnyHeader().AllowAnyMethod()));

builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = 429;
    o.AddFixedWindowLimiter("fixed", l =>
    {
        l.PermitLimit = 100;
        l.Window = TimeSpan.FromMinutes(1);
    });
});

var app = builder.Build();
app.UseHttpsRedirection();
app.UseCors("web");
app.UseRateLimiter();
```


## Trả lời câu hỏi tự kiểm tra

**3. Preflight `OPTIONS` được gửi trong trường hợp nào?**
Trình duyệt gửi preflight trước các request cross-origin "không đơn giản": dùng method như `PUT`, `DELETE`, `PATCH`, hoặc có header tùy chỉnh như `Authorization`, hoặc có `Content-Type: application/json`. Preflight dùng để hỏi server xem origin, method và header này có được phép không; server đồng ý thì trình duyệt mới gửi request thật. Request đơn giản (`GET`, `POST` form thông thường) không cần preflight.

**4. Tại sao truy vấn tham số hóa chặn được SQL Injection?**
Với truy vấn tham số hóa (`WHERE Email = @Email`), câu lệnh SQL và dữ liệu người dùng được gửi tách biệt. CSDL biên dịch cấu trúc câu lệnh trước, rồi chỉ coi giá trị truyền vào là dữ liệu thuần túy. Đầu vào như `' OR 1=1 --` chỉ bị hiểu là một chuỗi ký tự cần so khớp, không thể thay đổi logic câu lệnh. Khi nối chuỗi, đoạn chèn vào trở thành một phần của lệnh SQL và bị thực thi.

**5. Vì sao không lưu mật khẩu bằng SHA-256 thuần?**
- **Quá nhanh:** SHA-256 băm rất nhanh nên kẻ tấn công thử hàng tỷ mật khẩu mỗi giây bằng GPU (brute force, từ điển).
- **Không có salt:** hai người dùng cùng mật khẩu sẽ có cùng hash, dễ bị tra bằng rainbow table.
- **Cách đúng:** dùng hàm băm chậm có salt riêng như Argon2id hoặc bcrypt; salt nằm sẵn trong chuỗi hash.
