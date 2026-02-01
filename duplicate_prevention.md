# Duplicate Önleme Sistemi - Cüzdan İşlemleri

## Problem
Gmail ve Outlook'tan banka ekstresi/kredi kartı ekstresi içe aktarıldığında, manuel eklenen fatura ve abonelik ödemeleri ile çakışma (duplicate) oluyor ve bakiye yanlış hesaplanıyor.

## Çözüm

### 1. Ödeme Yöntemi Sınıflandırması

```dart
enum PaymentMethod {
  cash,           // Nakit - Manuel eklenir, hesaba dahil
  creditCard,     // Kredi Kartı - Ekstreden gelir, hesaba dahil
  debitCard,      // Banka Kartı - Ekstreden gelir, hesaba dahil
  bankTransfer,   // Banka Transferi - Ekstreden gelir, hesaba dahil
  autoPayment,    // Otomatik Ödeme - Hatırlatıcı, hesaba dahil DEĞİL
}
```

### 2. Yeni Model Alanları

**WalletTransaction** modeline eklenen alanlar:
- `paymentMethod`: Ödeme yöntemi
- `excludeFromBalance`: Bakiye hesaplamalarından hariç tut (true ise hesaba katılmaz)
- `linkedTransactionId`: Banka ekstresinden gelen işlem ile eşleşme ID'si

### 3. Kullanım Senaryoları

#### Senaryo 1: Nakit Harcama
```dart
WalletTransaction(
  amount: 50,
  categoryId: 'food_restaurant',
  paymentMethod: PaymentMethod.cash,
  excludeFromBalance: false, // Hesaba dahil
)
```
✅ Bakiyeye dahil edilir

#### Senaryo 2: Kredi Kartı ile Alışveriş
```dart
// Gmail'den otomatik import edilir
WalletTransaction(
  amount: 150,
  categoryId: 'shopping_clothing',
  paymentMethod: PaymentMethod.creditCard,
  excludeFromBalance: false, // Hesaba dahil
)
```
✅ Bakiyeye dahil edilir

#### Senaryo 3: Elektrik Faturası (Otomatik Ödeme)
```dart
// Kullanıcı manuel ekler (hatırlatıcı olarak)
WalletTransaction(
  amount: 200,
  categoryId: 'bills_electricity',
  paymentMethod: PaymentMethod.autoPayment,
  excludeFromBalance: true, // Hesaba dahil DEĞİL
  dueDate: DateTime(2026, 1, 15),
  isSubscription: false,
)
```
❌ Bakiyeye dahil edilmez (Çünkü kart ekstresinde zaten var)

#### Senaryo 4: Netflix Aboneliği (Otomatik Ödeme)
```dart
// Kullanıcı manuel ekler (hatırlatıcı olarak)
WalletTransaction(
  amount: 99.99,
  categoryId: 'entertainment_streaming',
  paymentMethod: PaymentMethod.autoPayment,
  excludeFromBalance: true, // Hesaba dahil DEĞİL
  recurrence: RecurrenceType.monthly,
  isSubscription: true,
)
```
❌ Bakiyeye dahil edilmez (Çünkü kart ekstresinde zaten var)

### 4. Bakiye Hesaplama Mantığı

```dart
double calculateBalance(List<WalletTransaction> transactions) {
  double balance = 0;
  
  for (var transaction in transactions) {
    // excludeFromBalance = true olanları atla
    if (transaction.excludeFromBalance) continue;
    
    if (transaction.type == TransactionType.income) {
      balance += transaction.amount;
    } else {
      balance -= transaction.amount;
    }
  }
  
  return balance;
}
```

### 5. Kullanıcı Bilgilendirmesi

**DuplicatePreventionInfo** widget'ı ile kullanıcıya açıklama gösterilir:

- 💵 **Nakit Ödemeler**: Manuel ekleyin. Bakiyenize dahil edilir.
- 💳 **Kart Ödemeleri**: Gmail/Outlook'tan otomatik gelir. Bakiyenize dahil edilir.
- 🧾 **Fatura/Abonelikler (Karttan)**: Hatırlatıcı olarak gösterilir. Bakiyenize dahil EDİLMEZ.

### 6. Gelecek İyileştirmeler

1. **Akıllı Eşleştirme**: Banka ekstresinden gelen işlem ile manuel eklenen fatura/aboneliği otomatik eşleştir
2. **Duplicate Uyarısı**: Aynı tarih, tutar ve kategori ile işlem eklenmeye çalışılırsa uyar
3. **İstatistikler**: "Hesaba dahil edilmeyen işlemler" raporu
4. **Kategori Bazlı Ayar**: Hangi kategorilerin otomatik olarak `excludeFromBalance = true` olacağını ayarla

## Örnek Kullanım Akışı

### Ay Başı:
1. Kullanıcı faturalarını manuel ekler (elektrik, su, internet)
   - `paymentMethod = autoPayment`
   - `excludeFromBalance = true`
   - Sadece hatırlatıcı olarak görünür

2. Kullanıcı aboneliklerini ekler (Netflix, Spotify)
   - `paymentMethod = autoPayment`
   - `excludeFromBalance = true`
   - `recurrence = monthly`

### Ay İçi:
3. Kullanıcı nakit harcamalarını ekler
   - `paymentMethod = cash`
   - `excludeFromBalance = false`
   - Bakiyeye dahil edilir

4. Gmail/Outlook entegrasyonu çalışır
   - Kart harcamaları otomatik import edilir
   - `paymentMethod = creditCard`
   - `excludeFromBalance = false`
   - Faturalar ve abonelikler de ekstrede görünür ama duplicate olmaz

### Sonuç:
✅ Bakiye doğru hesaplanır
✅ Duplicate kayıt olmaz
✅ Kullanıcı tüm harcamalarını görebilir
