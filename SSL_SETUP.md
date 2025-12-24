# SSL Sertifika Kurulumu

## Sorun

Nginx, SSL sertifikalarını bulamıyor. IP adresi için Let's Encrypt çalışmaz, self-signed sertifika kullanmalıyız.

## Çözüm: Self-Signed Sertifika Oluşturma

### Sunucuda Çalıştır:

```bash
# 1. Script'i çalıştırılabilir yap
cd /root/rewordly/rewordly-deploy
chmod +x ssl-setup.sh

# 2. SSL sertifikası oluştur
sudo ./ssl-setup.sh

# 3. Docker container'ları yeniden başlat
docker compose restart nginx
# veya
docker-compose restart nginx
```

### Manuel Oluşturma:

```bash
# Sertifika dizinini oluştur
sudo mkdir -p /etc/letsencrypt/live/161.35.153.201

# Self-signed sertifika oluştur
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/letsencrypt/live/161.35.153.201/privkey.pem \
  -out /etc/letsencrypt/live/161.35.153.201/fullchain.pem \
  -subj "/C=US/ST=State/L=City/O=Rewordly/CN=161.35.153.201" \
  -addext "subjectAltName=IP:161.35.153.201"

# İzinleri düzenle
sudo chmod 600 /etc/letsencrypt/live/161.35.153.201/privkey.pem
sudo chmod 644 /etc/letsencrypt/live/161.35.153.201/fullchain.pem
```

## Domain ile Let's Encrypt (Gelecekte)

Eğer bir domain'iniz varsa:

```bash
# 1. Nginx'i durdur (port 80 ve 443 boş olmalı)
docker compose stop nginx

# 2. Certbot ile sertifika oluştur
sudo certbot certonly --standalone -d yourdomain.com

# 3. Nginx config'i güncelle (domain adını değiştir)
# nginx.conf içinde: server_name yourdomain.com;

# 4. Nginx'i başlat
docker compose start nginx
```

## Test

```bash
# Sertifika kontrolü
sudo openssl x509 -in /etc/letsencrypt/live/161.35.153.201/fullchain.pem -text -noout

# Nginx test
docker compose exec nginx nginx -t
```

## Önemli Notlar

1. **Self-signed sertifika**: Tarayıcılar uyarı verecek, "Advanced" → "Proceed" yapmanız gerekecek
2. **Production**: Domain ile Let's Encrypt kullanın
3. **Sertifika süresi**: Self-signed sertifika 365 gün geçerli
4. **Yenileme**: Self-signed için otomatik yenileme yok, manuel yenilemeniz gerekir
