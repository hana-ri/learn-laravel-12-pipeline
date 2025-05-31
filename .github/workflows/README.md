# GitHub Actions Workflows

Repositori ini menggunakan GitHub Actions untuk mengotomatisasi proses CI/CD (Continuous Integration/Continuous Deployment) untuk aplikasi Laravel 12. Dokumentasi ini menjelaskan workflow yang tersedia dan cara penggunaannya.

## Alur Pipeline

```
Code Push → CI Pipeline → Build Images → CD Pipeline → Deploy to K8s
     ↓           ↓            ↓            ↓            ↓
   Tests    Lint/Build   Push to GHCR   SSH to Host   kubectl apply
```

## 📋 Daftar Workflows

### 1. [Laravel CI Pipeline](./ci.yml) 
**Trigger:** Push dan Pull Request ke branch `main` dan `dev`

Pipeline CI ini menjalankan serangkaian tes dan build yang diperlukan untuk memastikan kualitas kode sebelum deployment.

#### Tahapan CI:

**🧪 Test Job:**
- Setup PHP 8.4 dengan ekstensi yang diperlukan
- Install dependencies (Composer dan npm)
- Setup environment untuk testing
- Generate konfigurasi Ziggy
- Menjalankan ESLint untuk linting JavaScript/TypeScript
- Memeriksa format kode dengan Prettier
- Menjalankan Laravel Pint untuk standar kode PHP
- Build assets dengan Vite
- Menjalankan test suite dengan Pest (minimum coverage 85%)
- Upload laporan coverage sebagai artifact

**🏗️ Build Job:**
- Build Docker images untuk PHP-FPM dan Nginx
- Tag images dengan SHA commit dan `latest`
- Push images ke GitHub Container Registry (ghcr.io)

#### Environment Variables:
```yaml
IMAGE_PHP_FPM_BASE: ghcr.io/hana-ri/learn-laravel-12-pipeline/php-fpm
IMAGE_NGINX_BASE: ghcr.io/hana-ri/learn-laravel-12-pipeline/nginx
```

#### Required Secrets:
- `TEST_ENV_KEY`: Key untuk dekripsi environment testing
- `GITHUB_TOKEN`: Token untuk akses ke GitHub Container Registry

___

### 2. [Laravel CD Pipeline](./cd.yml)
**Trigger:** Setelah CI pipeline berhasil di branch `main`

Pipeline CD ini melakukan deployment otomatis ke environment production menggunakan Kubernetes.

#### Tahapan CD:

**🚀 Deploy Job:**
- Checkout kode terbaru
- Koneksi ke bastion host menggunakan SSH
- Pull perubahan terbaru dari Git
- Apply konfigurasi Kubernetes dari direktori `.k8s`

#### Required Secrets:
- `SSH_HOST`: Alamat IP atau hostname bastion host
- `SSH_USERNAME`: Username untuk koneksi SSH
- `SSH_PRIVATE_KEY`: Private key untuk autentikasi SSH

#### Fitur Rollback (Sementara Di-comment):
- Rollback otomatis jika deployment gagal
- Rollback deployment Kubernetes ke versi sebelumnya
- Verifikasi status rollback

---

## 🔧 Setup dan Konfigurasi

### Prerequisites:
1. **Docker Images**: Aplikasi harus memiliki Dockerfile yang menghasilkan images untuk PHP-FPM dan Nginx
2. **Kubernetes Manifests**: File konfigurasi Kubernetes harus tersedia di direktori `.k8s`
3. **Environment Encryption**: File environment untuk testing harus ter-enkripsi
4. **SSH Access**: Akses SSH ke bastion host untuk deployment

### Repository Secrets:
Pastikan secrets berikut telah dikonfigurasi di repository settings:

```
TEST_ENV_KEY          # Key untuk dekripsi environment testing
SSH_HOST              # IP/hostname bastion host
SSH_USERNAME          # Username SSH
SSH_PRIVATE_KEY       # Private key SSH
BASTION_HOST          # Hostname bastion host  
BASTION_USER          # Username bastion host
GITHUB_TOKEN          # Token GitHub (biasanya otomatis tersedia)
```

### Branches Strategy:
- **`main`**: Branch yang akan di-deploy otomatis
- **`dev`**: Branch untuk testing
- **Feature branches**: Akan menjalankan CI saat pull request ke `main` atau `dev`

---

## 🚀 Cara Penggunaan

### Deployment Otomatis:
1. Push perubahan ke branch `main`
2. CI pipeline akan berjalan otomatis
3. Jika CI berhasil, CD pipeline akan deploy ke production
4. Monitor status deployment di tab Actions

### Monitoring:
- **CI/CD Status**: Monitor di tab Actions GitHub
- **Deployment Status**: Cek status pods dan deployments di Kubernetes
- **Logs**: Lihat logs di GitHub Actions untuk troubleshooting

---

## 🛠️ Troubleshooting

### CI Pipeline Gagal:
- **Test Failure**: Periksa laporan test dan coverage
- **Linting Errors**: Jalankan `npm run lint` dan `vendor/bin/pint` locally
- **Build Errors**: Periksa konfigurasi Vite dan dependencies

### CD Pipeline Gagal:
- **SSH Connection**: Verifikasi SSH secrets dan konektivitas
- **Kubernetes Errors**: Periksa logs kubectl dan status cluster
- **Git Issues**: Pastikan branch `main` ter-update

### Rollback Gagal:
- **SSH Issues**: Periksa koneksi ke bastion host
- **Kubernetes Issues**: Verifikasi status deployments dan rollout history
- **Manual Intervention**: Lakukan rollback manual via kubectl jika diperlukan

---

## 📝 Notes

- Workflow ini menggunakan PHP 8.4 dan Laravel 12
- Minimum test coverage yang diperlukan adalah 85%
- Docker images di-push ke GitHub Container Registry
- Deployment menggunakan Kubernetes melalui bastion host
- Blum ada rollback