# Troubleshooting WebSocket Connection Issues

## Hızlı Kontrol

Sunucuda şu komutu çalıştır:
```bash
cd /root/rewordly/rewordly-deploy
chmod +x troubleshoot.sh
./troubleshoot.sh
```

## Yaygın Sorunlar ve Çözümleri

### 1. SSL Sertifikası Yok

**Hata:** `nginx: [emerg] cannot load certificate`

**Çözüm:**
```bash
cd /root/rewordly/rewordly-deploy
chmod +x ssl-setup.sh
sudo ./ssl-setup.sh
docker compose restart nginx
```

### 2. WebSocket Bağlantı Hatası

**Hata:** `WebSocket connection to 'wss://161.35.153.201/' failed`

**Kontroller:**

1. **Servisler çalışıyor mu?**
   ```bash
   docker compose ps
   ```
   Tüm servislerin `Up` durumunda olduğundan emin ol.

2. **Nginx logları:**
   ```bash
   docker compose logs nginx
   ```

3. **WebSocket server logları:**
   ```bash
   docker compose logs rewordly-server
   ```

4. **Portlar açık mı?**
   ```bash
   netstat -tuln | grep -E ':(80|443)'
   ```

5. **Firewall kontrolü:**
   ```bash
   # UFW kullanıyorsanız
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   
   # iptables kullanıyorsanız
   sudo iptables -L -n | grep -E ':(80|443)'
   ```

### 3. Nginx Yapılandırma Hatası

**Test:**
```bash
docker compose exec nginx nginx -t
```

**Yeniden yükle:**
```bash
docker compose restart nginx
```

### 4. WebSocket Server Çalışmıyor

**Kontrol:**
```bash
docker compose logs rewordly-server
docker compose exec rewordly-server node -e "console.log('Node.js works')"
```

**Yeniden başlat:**
```bash
docker compose restart rewordly-server
```

### 5. Network Sorunları

**Kontrol:**
```bash
# Docker network'i kontrol et
docker network inspect rewordly-deploy_rewordly-network

# Container'lar arası iletişim testi
docker compose exec nginx ping -c 2 rewordly-server
```

### 6. Self-Signed Sertifika Uyarısı

Chrome extension self-signed sertifikaları kabul eder, ancak tarayıcıda test ederken uyarı alırsın. Bu normaldir.

**Test için:**
```bash
# WSS bağlantısını test et
curl -k -v https://161.35.153.201
```

### 7. Extension'da Bağlantı Testi

Extension'ın console loglarını kontrol et:
1. Chrome'da `chrome://extensions/` aç
2. Rewordly extension'ını bul
3. "Inspect views: service worker" veya "Inspect views: popup" tıkla
4. Console'da WebSocket hatalarını kontrol et

## Tam Yeniden Başlatma

Tüm servisleri yeniden başlat:
```bash
cd /root/rewordly/rewordly-deploy
docker compose down
docker compose up -d --build
```

## Logları İzleme

Tüm servislerin loglarını gerçek zamanlı izle:
```bash
docker compose logs -f
```

Sadece belirli bir servis:
```bash
docker compose logs -f nginx
docker compose logs -f rewordly-server
```

## Test Komutları

### HTTPS Test
```bash
curl -k -I https://161.35.153.201
```

### WebSocket Test (Node.js ile)
```bash
node -e "const ws = require('ws'); const client = new ws.WebSocket('wss://161.35.153.201'); client.on('open', () => { console.log('Connected!'); client.close(); }); client.on('error', (e) => console.error('Error:', e));"
```

### Port Kontrolü
```bash
# Sunucuda
netstat -tuln | grep -E ':(80|443|8081)'

# Dışarıdan (local bilgisayarında)
telnet 161.35.153.201 443
```

## Hala Çalışmıyorsa

1. Tüm logları topla:
   ```bash
   docker compose logs > all_logs.txt
   ```

2. Servis durumlarını kontrol et:
   ```bash
   docker compose ps > services_status.txt
   ```

3. Nginx yapılandırmasını kontrol et:
   ```bash
   docker compose exec nginx cat /etc/nginx/conf.d/default.conf
   ```

