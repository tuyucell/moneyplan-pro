import React, { useState, useEffect } from 'react';
import {
    Card,
    InputNumber,
    Switch,
    Typography,
    Space,
    Row,
    Col,
    Button,
    Divider,
    Alert,
    Spin,
    Tag,
    Flex,
    App,
} from 'antd';
import {
    ThunderboltOutlined,
    ReloadOutlined,
    CrownOutlined,
    UserOutlined,
} from '@ant-design/icons';

const { Title, Text, Paragraph } = Typography;
import { API_BASE_URL } from '../config';

const BACKEND_URL = API_BASE_URL;

interface TierLimits {
    max_transactions: number;
    max_portfolios: number;
    max_alerts: number;
    max_bank_accounts: number;
    ai_requests_per_day: number;
    export_per_day: number;
    can_use_email_sync: boolean;
    can_use_advanced_charts: boolean;
    can_use_ai_analyst: boolean;
}

interface LimitsConfig {
    free_tier: TierLimits;
    pro_tier: TierLimits;
    rate_limits: {
        api_calls_per_minute: number;
        export_per_hour: number;
        ai_requests_per_hour: number;
        search_per_minute: number;
    };
    quotas: {
        max_storage_mb: number;
        max_api_calls_per_day: number;
        max_concurrent_sessions: number;
        data_retention_days: number;
    };
    enforce_limits: boolean;
    updated_at: string;
}

const LimitsManager: React.FC = () => {
    const [config, setConfig] = useState<LimitsConfig | null>(null);
    const [loading, setLoading] = useState(true);
    const [updating, setUpdating] = useState(false);
    const { message } = App.useApp();

    const fetchConfig = async () => {
        setLoading(true);
        try {
            const response = await fetch(`${BACKEND_URL}/api/v1/limits/config`);
            const data = await response.json();
            setConfig(data);
        } catch (error) {
            console.error(error);
            message.error('Limit ayarları yüklenemedi');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchConfig();
    }, []);

    const updateConfig = async (updates: Record<string, any>) => {
        setUpdating(true);
        try {
            const response = await fetch(`${BACKEND_URL}/api/v1/limits/config`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updates),
            });

            if (!response.ok) throw new Error('Güncelleme başarısız');
            const data = await response.json();
            setConfig(data);
            message.success('Limit ayarları güncellendi');
        } catch (error) {
            console.error(error);
            message.error('Güncelleme hatası');
        } finally {
            setUpdating(false);
        }
    };

    if (loading || !config) {
        return <div style={{ textAlign: 'center', padding: '50px' }}><Spin size="large" /></div>;
    }

    const renderLimitItem = (label: string, value: number, onChange: (val: number | null) => void) => (
        <Row align="middle" style={{ marginBottom: 12 }}>
            <Col span={16}><Text>{label}</Text></Col>
            <Col span={8}>
                <InputNumber
                    style={{ width: '100%' }}
                    value={value}
                    onChange={onChange}
                    formatter={(val) => val === -1 ? '∞' : `${val}`}
                    parser={(val) => val === '∞' ? '-1' : val as any}
                />
            </Col>
        </Row>
    );

    return (
        <div style={{ padding: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <div>
                    <Title level={2} style={{ margin: 0 }}>Limit ve Kota Yönetimi</Title>
                    <Text type="secondary">Kullanıcı katmanları (Free/Pro) ve sistem kotalarını belirleyin</Text>
                </div>
                <Space>
                    <Tag color={config.enforce_limits ? 'success' : 'error'}>
                        Sistem: {config.enforce_limits ? 'Aktif' : 'Limitler Pasif'}
                    </Tag>
                    <Button icon={<ReloadOutlined />} onClick={fetchConfig} disabled={updating}>Yenile</Button>
                </Space>
            </div>

            <Row gutter={[16, 16]}>
                {/* FREE TIER */}
                <Col xs={24} md={12}>
                    <Card title={<Space><UserOutlined /> Free Seviyesi</Space>}>
                        {renderLimitItem('Maks. İşlem Sayısı', config.free_tier.max_transactions, (v) => updateConfig({ free_max_transactions: v }))}
                        {renderLimitItem('Maks. Portföy Sayısı', config.free_tier.max_portfolios, (v) => updateConfig({ free_max_portfolios: v }))}
                        {renderLimitItem('Maks. Alarm Sayısı', config.free_tier.max_alerts, (v) => updateConfig({ free_max_alerts: v }))}
                        {renderLimitItem('Günlük AI İstek', config.free_tier.ai_requests_per_day, (v) => updateConfig({ free_ai_requests_per_day: v }))}
                        {renderLimitItem('Günlük Dışa Aktar (Export)', config.free_tier.export_per_day, (v) => updateConfig({ free_export_per_day: v }))}
                        {renderLimitItem('Maks. Banka Hesabı', config.free_tier.max_bank_accounts, (v) => updateConfig({ free_max_bank_accounts: v }))}
                        <Divider>Erişimler</Divider>
                        <Flex vertical style={{ width: '100%' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Text>Email Senkronizasyonu</Text>
                                <Switch checked={config.free_tier.can_use_email_sync} disabled />
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Text>Gelişmiş Grafikler (Advanced)</Text>
                                <Switch checked={config.free_tier.can_use_advanced_charts} disabled />
                            </div>
                        </Flex>
                    </Card>
                </Col>

                {/* PRO TIER */}
                <Col xs={24} md={12}>
                    <Card title={<Space><CrownOutlined style={{ color: '#faad14' }} /> Pro Seviyesi</Space>}>
                        {renderLimitItem('Maks. İşlem Sayısı', config.pro_tier.max_transactions, (v) => updateConfig({ pro_max_transactions: v }))}
                        {renderLimitItem('Maks. Portföy Sayısı', config.pro_tier.max_portfolios, (v) => updateConfig({ pro_max_portfolios: v }))}
                        {renderLimitItem('Maks. Alarm Sayısı', config.pro_tier.max_alerts, (v) => updateConfig({ pro_max_alerts: v }))}
                        <Alert
                            description={
                                <>
                                    <Text strong style={{ display: 'block', marginBottom: 4 }}>Profesyonel Kullanıcılar</Text>
                                    Pro kullanıcılar için yukarıdaki limitler genellikle sınırsız (-1) olarak belirlenir.
                                </>
                            }
                            type="info"
                            showIcon
                            style={{ marginTop: 20 }}
                        />
                    </Card>
                </Col>

                {/* RATE LIMITS & QUOTAS */}
                <Col xs={24}>
                    <Card title={<Space><ThunderboltOutlined /> Sistem Kotaları & Rate Limiting</Space>}>
                        <Row gutter={32}>
                            <Col xs={24} md={12}>
                                <Divider>Hız Limitleri (Dakika Başına)</Divider>
                                {renderLimitItem('API Çağrıları', config.rate_limits.api_calls_per_minute, (v) => updateConfig({ api_calls_per_minute: v }))}
                                {renderLimitItem('Arama İstekleri', config.rate_limits.search_per_minute, (v) => updateConfig({ search_per_minute: v }))}
                                {renderLimitItem('AI İstekleri (Saatlik)', config.rate_limits.ai_requests_per_hour, (v) => updateConfig({ ai_requests_per_hour: v }))}
                            </Col>
                            <Col xs={24} md={12}>
                                <Divider>Genel Kotalar</Divider>
                                {renderLimitItem('Maks. Depolama (MB)', config.quotas.max_storage_mb, (v) => updateConfig({ max_storage_mb: v }))}
                                {renderLimitItem('Günlük Toplam API Kotası', config.quotas.max_api_calls_per_day, (v) => updateConfig({ max_api_calls_per_day: v }))}
                                {renderLimitItem('Maks. Eşzamanlı Oturum', config.quotas.max_concurrent_sessions, (v) => updateConfig({ max_concurrent_sessions: v }))}
                            </Col>
                        </Row>
                    </Card>
                </Col>
            </Row>

            <div style={{ marginTop: 24, textAlign: 'center' }}>
                <Paragraph type="secondary">
                    Global Limit Denetimi: {' '}
                    <Switch
                        checked={config.enforce_limits}
                        onChange={(val) => updateConfig({ enforce_limits: val })}
                        checkedChildren="Açık"
                        unCheckedChildren="Kapalı"
                    />
                </Paragraph>
                <Text type="secondary" style={{ fontSize: 11 }}>
                    Son Güncelleme: {new Date(config.updated_at).toLocaleString()}
                </Text>
            </div>
        </div>
    );
};

export default LimitsManager;
