# Phần 2.3: Caching, tối ưu tốc độ API

- **Họ và tên:** Võ Nguyễn Đức Thiện 
- **Email:** vonguyenducthien2006@gmail.com
- **MSSV:** 0024418852
- **Lớp:** DHCNNTT24B-CS
- **Ngày thực hiện:** 21/10/2026

---


**Mục đích:** dùng bộ nhớ đệm trên RAM (Redis) để đọc dữ liệu nhanh và giảm tải cho CSDL chính.

### Mô hình Cache-aside (Lazy Loading)

```
Client → API → kiểm tra Redis
                 ├─ HIT:  có dữ liệu → trả về ngay
                 └─ MISS: không có → đọc CSDL → ghi vào Redis (kèm TTL) → trả về
```

| Khái niệm | Ý nghĩa |
|---|---|
| **Cache HIT** | Có sẵn dữ liệu trong Redis, trả về ngay |
| **Cache MISS** | Không có trong Redis, đọc từ CSDL rồi ghi kết quả vào Redis kèm TTL |
| **TTL (Time To Live)** | Hạn sử dụng của key; hết hạn thì dữ liệu cũ tự bị xóa, giải phóng bộ nhớ |
| **Invalidate** | Khi dữ liệu trong CSDL được sửa hoặc xóa, xóa key tương ứng trong Redis để tránh trả dữ liệu cũ |

### Thực hành với redis-cli

```bash
docker run -d --name redis -p 6379:6379 redis
docker exec -it redis redis-cli
```

```
SET course:1 "Lap trinh Web" EX 60
GET course:1
TTL course:1
DEL course:1
```

### Code minh họa (ASP.NET Core)

```csharp
builder.Services.AddStackExchangeRedisCache(o => o.Configuration = "localhost:6379");

app.MapGet("/api/v1/courses/{id}", async (int id, IDistributedCache cache, AppDbContext db) =>
{
    var key = $"course:{id}";

    var cached = await cache.GetStringAsync(key);          // HIT
    if (cached is not null)
        return Results.Content(cached, "application/json");

    var course = await db.Courses.FindAsync(id);           // MISS
    if (course is null) return Results.NotFound();

    var json = JsonSerializer.Serialize(course);
    await cache.SetStringAsync(key, json, new DistributedCacheEntryOptions
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)   // TTL
    });
    return Results.Content(json, "application/json");
});
```

---

## Trả lời câu hỏi tự kiểm tra

**1. Cache HIT và MISS khác nhau thế nào? TTL dùng để làm gì?**
- **HIT:** Redis đã có dữ liệu, API trả về ngay mà không đụng đến CSDL.
- **MISS:** Redis chưa có, API đọc từ CSDL, ghi kết quả vào Redis kèm TTL rồi trả về cho Client.
- **TTL (Time To Live)** là hạn sử dụng của key. Hết hạn thì Redis tự xóa, nhờ đó dữ liệu cũ không tồn tại mãi và bộ nhớ được giải phóng.

**2. Vì sao phải xóa key Redis khi cập nhật dữ liệu?**
Nếu chỉ sửa CSDL mà không xóa key, Redis vẫn giữ bản cũ và các request sau sẽ HIT, nhận dữ liệu cũ cho đến khi TTL hết hạn. Xóa (invalidate) key khiến lần đọc kế tiếp bị MISS, nên API đọc lại bản mới từ CSDL và nạp lại vào cache.
