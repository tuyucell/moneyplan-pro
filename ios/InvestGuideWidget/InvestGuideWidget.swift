import WidgetKit
import SwiftUI

// MARK: - Wallet Widget (Cüzdan & Hızlı Ekle)

struct WalletProvider: TimelineProvider {
    typealias Entry = WalletEntry

    func placeholder(in context: Context) -> WalletEntry {
        WalletEntry(date: Date(), totalBalance: "₺0,00", monthlyExpense: "₺0,00", isMasked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WalletEntry) -> ()) {
        let entry = WalletEntry(date: Date(), totalBalance: "₺0,00", monthlyExpense: "₺0,00", isMasked: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WalletEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.pro.moneyplan.app")

        let totalBalance = userDefaults?.string(forKey: "total_balance") ?? "₺0,00"
        let monthlyExpense = userDefaults?.string(forKey: "monthly_expense") ?? "₺0,00"
        let isMasked = userDefaults?.bool(forKey: "is_masked") ?? false

        let entry = WalletEntry(date: Date(), totalBalance: totalBalance, monthlyExpense: monthlyExpense, isMasked: isMasked)

        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

struct WalletEntry: TimelineEntry {
    let date: Date
    let totalBalance: String
    let monthlyExpense: String
    let isMasked: Bool
}

struct WalletWidgetEntryView : View {
    var entry: WalletProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        HStack(spacing: 0) {
            // Sol Taraf: Cüzdan Durumu
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text("Bakiye")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Link(destination: URL(string: "moneyplan:///navwallet")!) {
                        Image(systemName: entry.isMasked ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
                Text(entry.totalBalance)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.3))
                    .minimumScaleFactor(0.8)

                Spacer()

                Text("Giderler")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(entry.monthlyExpense)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 8)

            // Ayırıcı Çizgi (Sadece Medium)
            if family == .systemMedium {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 4)
            }

            // Sağ Taraf: Hızlı Ekle Butonları (Grid)
            if family == .systemMedium {
                let nonce = Int(Date().timeIntervalSince1970)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    QuickAddButton(icon: "cup.and.saucer.fill", label: "Kahve", amount: "100", color: .brown, url: "moneyplan:///quickadd?amount=100&category=Food&note=Kahve&u=\(nonce)_1")
                    QuickAddButton(icon: "fork.knife", label: "Yemek", amount: "300", color: .orange, url: "moneyplan:///quickadd?amount=300&category=Food&note=Yemek&u=\(nonce)_2")
                    QuickAddButton(icon: "basket.fill", label: "Market", amount: "500", color: .green, url: "moneyplan:///quickadd?amount=500&category=Shopping&note=Market&u=\(nonce)_3")
                    QuickAddButton(icon: "fuelpump.fill", label: "Yakıt", amount: "1000", color: .blue, url: "moneyplan:///quickadd?amount=1000&category=Transport&note=Yakit&u=\(nonce)_4")
                }
                .frame(width: 160) // Sağ tarafın genişliği
                .padding(.leading, 12)
            }
 else {
                 // Small boyutta sadece tek bir "Ekle" butonu
                 VStack {
                     Spacer()
                     Link(destination: URL(string: "moneyplan:///addexpense")!) {
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 40, height: 40)
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                 }
            }
        }
        .padding()
        .background(Color.white)
    }
}

struct QuickAddButton: View {
    let icon: String
    let label: String
    let amount: String
    let color: Color
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                Text("\(amount)₺")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.9))
            .cornerRadius(10)
        }
    }
}

struct WalletWidget: Widget {
    let kind: String = "WalletWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WalletProvider()) { entry in
            if #available(iOS 17.0, *) {
                WalletWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WalletWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.white)
            }
        }
        .configurationDisplayName("Cüzdan Özeti")
        .description("Bakiyeni gör ve hızlıca harcama ekle.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle (Ana Giriş Noktası)

@main
struct InvestGuideWidgetBundle: WidgetBundle {
    var body: some Widget {
        WalletWidget()
    }
}
