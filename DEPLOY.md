# 部署指南

## 目录结构

```
Flutter-warehouse/
├── warehouse-api/        ← NestJS 后端
└── flutter_warehouse/    ← Flutter 前端
```

---

## 一、后端部署（腾讯云服务器）

### 1. 服务器准备

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker && systemctl start docker

# 安装 Docker Compose
apt install docker-compose-plugin -y
```

### 2. 上传代码

```bash
# 本地执行：将 warehouse-api 上传到服务器
scp -r ./warehouse-api ubuntu@YOUR_SERVER_IP:/home/ubuntu/
```

### 3. 配置环境变量

```bash
# 在服务器上
cd /home/ubuntu/warehouse-api
cp .env.example .env

# 编辑 .env，修改以下两项为随机强密码
nano .env
# JWT_SECRET=替换为随机字符串（至少32位）
# JWT_REFRESH_SECRET=替换为另一个随机字符串
```

### 4. 启动服务

```bash
cd /home/ubuntu/warehouse-api
docker compose up -d --build

# 查看状态
docker compose ps
docker compose logs -f api
```

后端将运行在 `http://YOUR_SERVER_IP:3000`

### 5. Nginx 反向代理（推荐）

```bash
apt install nginx -y
```

创建配置文件 `/etc/nginx/sites-available/warehouse`：

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 或服务器 IP

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 20m;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/warehouse /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 6. HTTPS（可选，推荐生产使用）

```bash
apt install certbot python3-certbot-nginx -y
certbot --nginx -d your-domain.com
```

---

## 二、Flutter 前端配置

### 1. 修改 API 地址

编辑 [lib/core/constants.dart](flutter_warehouse/lib/core/constants.dart)：

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
// 如果有域名和 HTTPS：
// static const String baseUrl = 'https://your-domain.com/api';
```

### 2. 安装依赖并运行

```bash
cd flutter_warehouse
flutter pub get
flutter run            # 调试运行
flutter build apk      # 打包 Android APK
flutter build ios      # 打包 iOS（需要 Mac）
```

### 3. APK 安装路径

打包完成后，APK 在：
```
flutter_warehouse/build/app/outputs/flutter-apk/app-release.apk
```

---

## 三、API 接口一览

| 模块 | 方法 | 路径 | 权限 |
|------|------|------|------|
| 认证 | POST | /api/auth/register | 公开 |
| 认证 | POST | /api/auth/login | 公开 |
| 认证 | POST | /api/auth/refresh | 公开 |
| 认证 | POST | /api/auth/change-password | 登录 |
| 用户 | GET | /api/users | admin |
| 用户 | PATCH | /api/users/:id/role | admin |
| 用户 | DELETE | /api/users/:id | admin |
| SKU | GET | /api/skus | 登录 |
| SKU | POST | /api/skus | editor+ |
| SKU | PATCH | /api/skus/:id | editor+ |
| SKU | DELETE | /api/skus/:id | editor+ |
| 位置 | GET | /api/locations | 登录 |
| 位置 | POST | /api/locations | editor+ |
| 位置 | PATCH | /api/locations/:id | editor+ |
| 位置 | DELETE | /api/locations/:id | editor+ |
| 库存 | GET | /api/inventory | 登录 |
| 库存 | PUT | /api/inventory | editor+ |
| 库存 | DELETE | /api/inventory/:id | editor+ |
| 库存 | DELETE | /api/inventory | admin（清空）|
| 记录 | GET | /api/history | 登录 |
| 导入 | POST | /api/import/csv | editor+ |

---

## 四、常用运维命令

```bash
# 重启后端
docker compose restart api

# 查看日志
docker compose logs -f api

# 备份 MongoDB 数据
docker exec warehouse-mongo mongodump --out /backup
docker cp warehouse-mongo:/backup ./backup

# 更新后端
git pull
docker compose up -d --build api
```

---

## 五、CSV 导入格式

CSV 文件需包含以下列（列名大小写不敏感）：

| 列名 | 说明 | 必填 |
|------|------|------|
| sku / item / code | SKU 编号 | ✅ |
| location / loc | 位置代码 | ✅ |
| qty / quantity | 数量（箱） | ✅ |
| name | 产品名称 | 可选 |
| barcode | 条码 | 可选 |
| carton_qty | 每箱个数 | 可选 |

示例：
```csv
sku,location,qty,name,barcode
ABC001,A1B,10,产品A,1234567890
ABC002,B2C,5,产品B,0987654321
```
