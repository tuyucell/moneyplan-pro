import {
    Typography,
    Card,
    Row,
    Col,
    Divider,
    Space,
    Flex,
    Timeline,
    Tag,
} from 'antd';
import {
    BookOutlined,
    DashboardOutlined,
    UserOutlined,
    DollarOutlined,
    SettingOutlined,
    NotificationOutlined,
    ToolOutlined,
    BarChartOutlined,
    CheckCircleOutlined,
    InfoCircleOutlined,
} from '@ant-design/icons';

const { Title, Text, Paragraph } = Typography;

export default function AdminGuide() {
    return (
        <div style={{ maxWidth: 1000, margin: '0 auto', paddingBottom: 40 }}>
            {/* Header Section */}
            <Flex vertical align="center" style={{ marginBottom: 48, textAlign: 'center' }}>
                <BookOutlined style={{ fontSize: 48, color: '#1890ff', marginBottom: 16 }} />
                <Title level={1}>Yönetici Kullanım Kılavuzu</Title>
                <Paragraph style={{ fontSize: 16, color: '#666' }}>
                    MoneyPlan Pro admin panelini verimli kullanmanız için kapsamlı rehber.
                </Paragraph>
            </Flex>

            {/* Overview Sections */}
            <Row gutter={[24, 24]}>
                {/* 1. Dashboard */}
                <Col span={24}>
                    <Card
                        title={<Space><DashboardOutlined /> 1. Dashboard (Genel Bakış)</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
                    >
                        <Paragraph>
                            Dashboard, uygulamanın anlık sağlık durumunu ve büyüme verilerini gösteren ana merkezdir.
                        </Paragraph>
                        <Timeline
                            items={[
                                { label: 'Metrikler', children: 'Total Users, MAU/DAU ve Premium Dönüşüm oranlarını takip edin.' },
                                { label: 'Segmentasyon', children: 'Kullanıcıların sadakat düzeylerini (RFM Analizi) analiz edin.' },
                            ]}
                        />
                    </Card>
                </Col>

                {/* 2. User Management */}
                <Col span={24}>
                    <Card
                        title={<Space><UserOutlined /> 2. Kullanıcı Yönetimi (Users)</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
                    >
                        <Paragraph>
                            Kullanıcı listesini görebilir, durumlarını değiştirebilir ve etkileşim puanlarını analiz edebilirsiniz.
                        </Paragraph>
                        <Flex gap="middle" wrap="wrap">
                            <Tag color="green" icon={<CheckCircleOutlined />}>Engagement Score: Etkileşim düzeyi takibi</Tag>
                            <Tag color="red" icon={<InfoCircleOutlined />}>Ban/Unban: Kural ihlali yönetimi</Tag>
                            <Tag color="gold" icon={<DollarOutlined />}>Manual Premium: Elle yetki tanımlama</Tag>
                        </Flex>
                    </Card>
                </Col>

                {/* 3. Pricing */}
                <Col span={24}>
                    <Card
                        title={<Space><DollarOutlined /> 3. Fiyatlandırma ve Kampanya Yönetimi</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
                    >
                        <Row gutter={16}>
                            <Col span={12}>
                                <Text strong>Fiyat Güncelleme:</Text>
                                <Paragraph type="secondary">Aylık ve yıllık planların baz fiyatlarını (USD/TRY) anlık güncelleyin.</Paragraph>
                            </Col>
                            <Col span={12}>
                                <Text strong>Kampanyalar:</Text>
                                <Paragraph type="secondary">%20 indirim gibi promosyonları tarih bazlı tanımlayın.</Paragraph>
                            </Col>
                        </Row>
                    </Card>
                </Col>

                {/* 4. Settings */}
                <Col span={24}>
                    <Card
                        title={<Space><SettingOutlined /> 4. Sistem Konfigürasyonu</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
                    >
                        <Paragraph>
                            Uygulama çekirdek ayarlarını ve <strong>Feature Flags</strong> (özellik anahtarları) ayarlarını yönetin.
                            Yeni özellikleri uygulama güncellemesi gerekmeden anlık açıp kapatabilirsiniz.
                        </Paragraph>
                        <Tag color="blue">API Anahtarları</Tag>
                        <Tag color="purple">Özellik Yönetimi</Tag>
                        <Tag color="orange">Önbellek (Cache) Yönetimi</Tag>
                    </Card>
                </Col>

                {/* 5. Ads & Tasks */}
                <Col xs={24} md={12}>
                    <Card
                        title={<Space><NotificationOutlined /> 5. Reklam Yönetimi</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)', height: '100%' }}
                    >
                        <Paragraph>
                            AdMob Unit ID'lerini yönetin ve reklam yerleşimlerini kontrol edin.
                        </Paragraph>
                    </Card>
                </Col>
                <Col xs={24} md={12}>
                    <Card
                        title={<Space><ToolOutlined /> 6. Sistem Görevleri</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)', height: '100%' }}
                    >
                        <Paragraph>
                            Veri temizleme, borsa fiyat senkronizasyonu gibi teknik script'leri manuel tetikleyin.
                        </Paragraph>
                    </Card>
                </Col>

                {/* 7. Analytics */}
                <Col span={24}>
                    <Card
                        title={<Space><BarChartOutlined /> 7. Analiz ve Canlı İzleme</Space>}
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}
                    >
                        <div style={{ marginBottom: 16 }}>
                            <Text strong>Churn Prediction:</Text> Uygulamayı bırakma riski olan kullanıcıları görün.
                        </div>
                        <div>
                            <Text strong>Live Feed:</Text> Şu an uygulamada olan kullanıcıların hangi ekranda ne yaptığını anlık izleyin.
                        </div>
                    </Card>
                </Col>
            </Row>

            <Divider />

            {/* Footer Note */}
            <Paragraph type="secondary" style={{ textAlign: 'center' }}>
                Hata bildirimleri ve teknik destek için lütfen sistem loglarını kontrol ediniz. <br />
                <em>Geliştiren: Antigravity AI Assistant</em>
            </Paragraph>
        </div>
    );
}
