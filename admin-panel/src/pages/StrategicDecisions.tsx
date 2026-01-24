import { useQuery } from '@tanstack/react-query';
import {
    Card,
    Row,
    Col,
    Typography,
    Table,
    Tag,
    Space,
    Flex,
    Spin,
    Empty,
    Alert,
} from 'antd';
import {
    PieChart,
    Pie,
    Cell,
    BarChart,
    Bar,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip as RechartTooltip,
    Legend,
    ResponsiveContainer,
} from 'recharts';
import {
    RocketOutlined,
    HeatMapOutlined,
    UsergroupAddOutlined,
    WarningOutlined,
    RiseOutlined,
} from '@ant-design/icons';
import { supabase } from '../lib/supabase';

const { Title, Paragraph } = Typography;

const COLORS = ['#1890ff', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

export default function StrategicDecisions() {
    // 1. Data Fetching
    const { data: cohortData, isLoading: cohortLoading } = useQuery({
        queryKey: ['cohort-retention'],
        queryFn: async () => {
            const { data, error } = await supabase.rpc('get_cohort_retention');
            if (error) throw error;
            return data;
        }
    });

    const { data: featureData, isLoading: featureLoading } = useQuery({
        queryKey: ['feature-distribution'],
        queryFn: async () => {
            const { data, error } = await supabase.rpc('get_feature_usage_distribution');
            if (error) throw error;
            return data;
        }
    });

    const { data: segmentData, isLoading: segmentLoading } = useQuery({
        queryKey: ['user-segmentation'],
        queryFn: async () => {
            const { data, error } = await supabase.rpc('get_user_segmentation');
            if (error) throw error;
            return data;
        }
    });

    const { data: anomalyData, isLoading: anomalyLoading } = useQuery({
        queryKey: ['anomaly-detection'],
        queryFn: async () => {
            const { data, error } = await supabase.rpc('get_anomaly_detection');
            if (error) throw error;
            return data;
        }
    });

    if (cohortLoading || featureLoading || segmentLoading || anomalyLoading) {
        return <div style={{ textAlign: 'center', padding: '100px' }}><Spin size="large" /></div>;
    }

    return (
        <div style={{ padding: '0px' }}>
            <Flex justify="space-between" align="center" style={{ marginBottom: '24px' }}>
                <Title level={2} style={{ margin: 0 }}>🧠 Strategic Decision Panel</Title>
                <Tag color="purple" icon={<RocketOutlined />}>AI Supported Insights</Tag>
            </Flex>

            <Alert
                message="Decision Maker Mode"
                description="Bu sayfa sadece veri göstermez; düşük tutunma (retention) veya şüpheli işlemlerde aksiyon almanız için sinyaller üretir."
                type="info"
                showIcon
                style={{ marginBottom: '24px' }}
            />

            <Row gutter={[16, 16]}>
                {/* 1. Cohort Analysis Matrix */}
                <Col span={24}>
                    <Card title={<Space><HeatMapOutlined /> Cohort Retention Analysis (Weekly)</Space>} style={{ borderRadius: '12px' }}>
                        <Paragraph type="secondary">Yeni kullanıcıların haftalık bazda uygulamada kalma oranları. %30 ve altı riskli kabul edilir.</Paragraph>
                        <Table
                            dataSource={cohortData || []}
                            pagination={false}
                            size="small"
                            columns={[
                                { title: 'Cohort (Week)', dataIndex: 'cohort_week', key: 'cohort', render: (val: string) => new Date(val).toLocaleDateString() },
                                { title: 'Size', dataIndex: 'cohort_size', key: 'size' },
                                { title: 'W0', render: (_, r: any) => r.week_number === 0 ? <Tag color="blue">{r.retention_rate}%</Tag> : null },
                                {
                                    title: 'W1-W12 Retention',
                                    key: 'retention',
                                    render: (_, r: any) => (
                                        <Tag color={r.retention_rate < 30 ? 'volcano' : 'green'}>
                                            {r.week_number > 0 ? `W${r.week_number}: ${r.retention_rate}%` : '-'}
                                        </Tag>
                                    )
                                }
                            ]}
                        />
                    </Card>
                </Col>

                {/* 2. Feature Usage Heatmap */}
                <Col span={12}>
                    <Card title={<Space><RiseOutlined /> Feature Usage Distribution</Space>} style={{ height: '400px', borderRadius: '12px' }}>
                        <ResponsiveContainer width="100%" height={300}>
                            <BarChart data={featureData?.slice(0, 8)}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                <XAxis dataKey="activity_name" tick={{ fontSize: 10 }} />
                                <YAxis />
                                <RechartTooltip />
                                <Bar dataKey="usage_count" fill="#1890ff" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>

                {/* 3. User Segmentation */}
                <Col span={12}>
                    <Card title={<Space><UsergroupAddOutlined /> User Segmentation (30 Days)</Space>} style={{ height: '400px', borderRadius: '12px' }}>
                        <ResponsiveContainer width="100%" height={300}>
                            <PieChart>
                                <Pie
                                    data={segmentData || []}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={80}
                                    paddingAngle={5}
                                    dataKey="user_count"
                                    nameKey="segment"
                                >
                                    {(segmentData || []).map((_entry: any) => (
                                        <Cell key={_entry.segment} fill={COLORS[(segmentData || []).indexOf(_entry) % COLORS.length]} />
                                    ))}
                                </Pie>
                                <RechartTooltip />
                                <Legend />
                            </PieChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>

                {/* 4. Anomaly & Fraud Signals */}
                <Col span={24}>
                    <Card title={<Space><WarningOutlined style={{ color: '#ef4444' }} /> Anomaly & Fraud Signals</Space>} style={{ borderRadius: '12px' }}>
                        {!anomalyData || anomalyData.length === 0 ? (
                            <Empty description="No suspicious activity detected." />
                        ) : (
                            <Table
                                dataSource={anomalyData}
                                pagination={false}
                                columns={[
                                    { title: 'Type', dataIndex: 'anomaly_type', key: 'type', render: (t) => <Tag color="error">{t}</Tag> },
                                    { title: 'User', dataIndex: 'user_email', key: 'user' },
                                    { title: 'Details', dataIndex: 'ip_count', key: 'details', render: (v, r: any) => v ? `${v} distinct IPs` : `${r.action_count} actions/min` },
                                    { title: 'Severity', dataIndex: 'severity', key: 'severity', render: (s) => <Tag color={s === 'Critical' ? 'magenta' : 'orange'}>{s}</Tag> },
                                    { title: 'Latest', dataIndex: 'latest_event', key: 'latest', render: (d) => new Date(d).toLocaleString() },
                                ]}
                            />
                        )}
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
