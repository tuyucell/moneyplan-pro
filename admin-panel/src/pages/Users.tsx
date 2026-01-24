import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Card,
    Table,
    Input,
    Tag,
    Space,
    Button,
    Modal,
    Descriptions,
    Typography,
    Badge,
    Select,
    Spin,
    Alert,
    Flex,
    Avatar,
    Progress,
} from 'antd';
import {
    SearchOutlined,
    UserOutlined,
    CrownOutlined,
    CheckCircleOutlined,
    EyeOutlined,
    DownloadOutlined,
    BarChartOutlined,
    StopOutlined,
    MailOutlined,
} from '@ant-design/icons';
import type { ColumnsType } from 'antd/es/table';
import {
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip as RechartsTooltip,
    ResponsiveContainer,
} from 'recharts';
import { supabase } from '../lib/supabase';
import { exportToCSV, exportToJSON, formatDateForFilename } from '../utils/export';

const { Title, Text } = Typography;
const { Search } = Input;

const getScoreColor = (score: number) => {
    if (score > 80) return '#10b981';
    if (score > 50) return '#6366f1';
    return '#f59e0b';
};

interface User {
    id: string;
    email: string;
    display_name: string | null;
    is_premium: boolean;
    is_active: boolean;
    is_banned: boolean;
    auth_provider: string;
    created_at: string;
    last_seen_at: string | null;
    birth_year: number | null;
    gender: string | null;
    occupation: string | null;
    financial_goal: string | null;
    risk_tolerance: string | null;
    engagement_score?: number;
}

interface UserActivityTimeline {
    activity_date: string;
    activity_timestamp: string;
    event_name: string;
    metadata: any;
}

const UserStatusTag = ({ record }: { record: User }) => {
    if (record.is_banned) {
        return <Tag icon={<StopOutlined />} color="error" style={{ borderRadius: '4px' }}>Banned</Tag>;
    }
    if (record.is_active) {
        return <Tag icon={<CheckCircleOutlined />} color="success" style={{ borderRadius: '4px' }}>Active</Tag>;
    }
    return <Tag color="default" style={{ borderRadius: '4px' }}>Inactive</Tag>;
};

const UserStatusDescription = ({ record }: { record: User }) => {
    if (record.is_banned) return <Tag color="red">Banned</Tag>;
    if (record.is_active) return <Tag color="green">Active</Tag>;
    return <Tag>Inactive</Tag>;
};

const ActivityModalContent = ({
    loading,
    data,
    chartData
}: {
    loading: boolean,
    data: any,
    chartData: any[]
}) => {
    if (loading) {
        return <div style={{ textAlign: 'center', padding: '40px' }}><Spin size="large" /></div>;
    }

    if (data && data.length > 0) {
        return (
            <>
                <Card size="small" title="Activity Intensity (Last 30 Days)" style={{ marginBottom: '16px' }}>
                    <div style={{ height: 200, width: '100%' }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={chartData}>
                                <defs>
                                    <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#1890ff" stopOpacity={0.8} />
                                        <stop offset="95%" stopColor="#1890ff" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                <XAxis dataKey="date" fontSize={10} />
                                <YAxis fontSize={10} />
                                <RechartsTooltip
                                    formatter={(value: any, name: string | undefined) => [
                                        name === 'duration' ? `${(Number(value) / 60).toFixed(1)} min` : value,
                                        name === 'duration' ? 'Total Time' : 'Total Events'
                                    ]}
                                />
                                <Area
                                    type="monotone"
                                    dataKey="count"
                                    stroke="#1890ff"
                                    fillOpacity={1}
                                    fill="url(#colorCount)"
                                    name="Events"
                                />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </Card>

                <Table
                    dataSource={data as UserActivityTimeline[]}
                    rowKey={(record) => `${record.activity_timestamp}-${record.event_name}`}
                    pagination={{ pageSize: 8, showSizeChanger: false }}
                    size="small"
                    columns={[
                        {
                            title: 'Time',
                            dataIndex: 'activity_timestamp',
                            key: 'timestamp',
                            width: 100,
                            render: (ts: string) => <Text type="secondary" style={{ fontSize: '12px' }}>{new Date(ts).toLocaleTimeString()}</Text>,
                        },
                        {
                            title: 'Action',
                            dataIndex: 'event_name',
                            key: 'event',
                            render: (name: string) => (
                                <Tag color={name.includes('error') ? 'red' : 'blue'} style={{ fontSize: '11px', borderRadius: '4px' }}>
                                    {name.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')}
                                </Tag>
                            )
                        },
                        {
                            title: 'Screen / Data',
                            key: 'detail',
                            render: (record: UserActivityTimeline) => {
                                const meta = record.metadata || {};
                                const val = meta.screen_name || meta.page_path || meta.category || meta.item_name || '-';
                                return <Text style={{ fontSize: '13px' }}>{val}</Text>;
                            }
                        }
                    ]}
                />
            </>
        );
    }

    return <Alert description="No specific activity recorded in visual timeline" type="info" showIcon />;
};

export default function Users() {
    const [searchText, setSearchText] = useState('');
    const [filterPremium, setFilterPremium] = useState<boolean | 'all'>('all');
    const [selectedUser, setSelectedUser] = useState<User | null>(null);
    const [detailsModalOpen, setDetailsModalOpen] = useState(false);
    const [activityModalOpen, setActivityModalOpen] = useState(false);
    const [activityUserId, setActivityUserId] = useState<string | null>(null);

    const { data: users, isLoading } = useQuery({
        queryKey: ['users'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('users')
                .select('*')
                .is('deleted_at', null)
                .order('created_at', { ascending: false })
                .limit(1000);

            if (error) throw error;
            return data as User[];
        },
    });

    const { data: userActivity, isLoading: activityLoading } = useQuery({
        queryKey: ['user-activity', activityUserId],
        queryFn: async () => {
            if (!activityUserId) return null;
            const { data, error } = await supabase.rpc('get_user_activity_timeline', {
                p_user_id: activityUserId,
                p_days_back: 30
            });
            if (error) throw error;
            return data;
        },
        enabled: !!activityUserId,
    });

    const activityChartData = userActivity ? (userActivity as UserActivityTimeline[]).reduce((acc: any[], item) => {
        const date = new Date(item.activity_timestamp).toLocaleDateString();
        const existing = acc.find(a => a.date === date);
        const duration = Number(item.metadata?.duration_seconds || item.metadata?.time_spent || 0);

        if (existing) {
            existing.count += 1;
            existing.duration += duration;
        } else {
            acc.push({ date, count: 1, duration });
        }
        return acc;
    }, []).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()) : [];

    const filteredUsers = users?.filter((user) => {
        const matchesSearch =
            user.email.toLowerCase().includes(searchText.toLowerCase()) ||
            user.display_name?.toLowerCase().includes(searchText.toLowerCase());

        const matchesPremium =
            filterPremium === 'all' || user.is_premium === filterPremium;

        return matchesSearch && matchesPremium;
    });

    const columns: ColumnsType<User> = [
        {
            title: 'User Profile',
            dataIndex: 'email',
            key: 'email',
            render: (email: string, record: User) => (
                <Space size="middle">
                    <Badge dot status={record.is_active ? 'success' : 'default'} offset={[-4, 32]}>
                        <Avatar
                            icon={<UserOutlined />}
                            style={{
                                backgroundColor: record.is_premium ? '#f59e0b' : '#6366f1',
                                border: '2px solid white',
                                boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                            }}
                            size="large"
                        />
                    </Badge>
                    <Flex vertical gap={0}>
                        <Text strong style={{ fontSize: '15px' }}>{record.display_name || 'InvestGuide User'}</Text>
                        <Space size={4}>
                            <MailOutlined style={{ fontSize: '12px', color: '#8c8c8c' }} />
                            <Text type="secondary" style={{ fontSize: '12px' }}>{email}</Text>
                        </Space>
                    </Flex>
                </Space>
            ),
        },
        {
            title: 'Level & Identity',
            key: 'identity',
            width: 180,
            render: (record: User) => (
                <Flex vertical gap="small">
                    <Flex gap="x-small" align="center">
                        {record.is_premium ? (
                            <Tag icon={<CrownOutlined />} color="gold" style={{ borderRadius: '12px', padding: '0 10px' }}>
                                Premium
                            </Tag>
                        ) : (
                            <Tag style={{ borderRadius: '12px', padding: '0 10px' }}>Free</Tag>
                        )}
                    </Flex>
                    <Space size={4}>
                        <Tag color="blue" style={{ fontSize: '11px', borderRadius: '4px' }}>{record.auth_provider.toUpperCase()}</Tag>
                        <UserStatusTag record={record} />
                    </Space>
                </Flex>
            ),
        },
        {
            title: 'Engagement Score',
            dataIndex: 'engagement_score',
            key: 'score',
            width: 180,
            render: (score: number) => (
                <Flex vertical gap={4} style={{ width: '120px' }}>
                    <Flex justify="space-between">
                        <Text style={{ fontSize: '11px' }} type="secondary">Activity</Text>
                        <Text style={{ fontSize: '11px' }} strong>{score}%</Text>
                    </Flex>
                    <Progress
                        percent={score}
                        size="small"
                        showInfo={false}
                        strokeColor={getScoreColor(score)}
                    />
                </Flex>
            )
        },
        {
            title: 'Joined',
            dataIndex: 'created_at',
            key: 'created_at',
            width: 150,
            render: (date: string) => new Date(date).toLocaleDateString(),
        },
        {
            title: 'Last Seen',
            dataIndex: 'last_seen_at',
            key: 'last_seen_at',
            width: 150,
            render: (date: string | null) =>
                date ? new Date(date).toLocaleDateString() : 'Never',
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 120,
            render: (record: User) => (
                <Space>
                    <Button
                        icon={<EyeOutlined />}
                        onClick={() => {
                            setSelectedUser(record);
                            setDetailsModalOpen(true);
                        }}
                    >
                        Details
                    </Button>
                    <Button
                        icon={<BarChartOutlined />}
                        onClick={() => {
                            setActivityUserId(record.id);
                            setActivityModalOpen(true);
                        }}
                    >
                        Activity
                    </Button>
                </Space>
            ),
        },
    ];

    return (
        <div>
            <Title level={2} style={{ marginBottom: '24px' }}>
                👥 Users
            </Title>

            <Card>
                <Flex vertical gap="large" style={{ width: '100%' }}>
                    {/* Filters */}
                    <Space wrap style={{ width: '100%', justifyContent: 'space-between' }}>
                        <Space wrap>
                            <Search
                                placeholder="Search by email or name"
                                prefix={<SearchOutlined />}
                                onChange={(e) => setSearchText(e.target.value)}
                                style={{ width: 300 }}
                                allowClear
                            />
                            <Select
                                value={filterPremium}
                                onChange={setFilterPremium}
                                style={{ width: 150 }}
                            >
                                <Select.Option value="all">All Users</Select.Option>
                                <Select.Option value={true}>Premium Only</Select.Option>
                                <Select.Option value={false}>Free Only</Select.Option>
                            </Select>
                        </Space>
                        <Space>
                            <Button
                                icon={<DownloadOutlined />}
                                onClick={() => exportToCSV(
                                    (filteredUsers || []) as any,
                                    `users-${formatDateForFilename()}`
                                )}
                                disabled={!filteredUsers || filteredUsers.length === 0}
                            >
                                Export CSV
                            </Button>
                            <Button
                                icon={<DownloadOutlined />}
                                onClick={() => exportToJSON(
                                    filteredUsers || [],
                                    `users-${formatDateForFilename()}`
                                )}
                                disabled={!filteredUsers || filteredUsers.length === 0}
                            >
                                Export JSON
                            </Button>
                        </Space>
                    </Space>

                    {/* Stats */}
                    <Space size="large">
                        <Badge
                            count={filteredUsers?.length || 0}
                            showZero
                            color="#1890ff"
                            overflowCount={9999}
                        >
                            <Text strong style={{ marginRight: '8px' }}>
                                Total Users
                            </Text>
                        </Badge>
                        <Badge
                            count={
                                filteredUsers?.filter((u) => u.is_premium).length || 0
                            }
                            showZero
                            color="gold"
                        >
                            <Text strong style={{ marginRight: '8px' }}>
                                Premium Users
                            </Text>
                        </Badge>
                        <Badge
                            count={
                                filteredUsers?.filter((u) => u.is_banned).length || 0
                            }
                            showZero
                            color="red"
                        >
                            <Text strong style={{ marginRight: '8px' }}>
                                Banned Users
                            </Text>
                        </Badge>
                    </Space>

                    {/* Table */}
                    <Table
                        columns={columns}
                        dataSource={filteredUsers}
                        loading={isLoading}
                        rowKey="id"
                        pagination={{
                            pageSize: 20,
                            showSizeChanger: true,
                            showTotal: (total) => `Total ${total} users`,
                        }}
                    />
                </Flex>
            </Card>

            {/* User Details Modal */}
            <Modal
                title="User Details"
                open={detailsModalOpen}
                onCancel={() => setDetailsModalOpen(false)}
                width={700}
                footer={[
                    <Button key="close" onClick={() => setDetailsModalOpen(false)}>
                        Close
                    </Button>,
                ]}
            >
                {selectedUser && (
                    <Descriptions bordered column={2}>
                        <Descriptions.Item label="Email" span={2}>
                            {selectedUser.email}
                        </Descriptions.Item>
                        <Descriptions.Item label="Display Name" span={2}>
                            {selectedUser.display_name || 'N/A'}
                        </Descriptions.Item>
                        <Descriptions.Item label="User ID" span={2}>
                            <Text copyable>{selectedUser.id}</Text>
                        </Descriptions.Item>
                        <Descriptions.Item label="Premium">
                            {selectedUser.is_premium ? (
                                <Tag icon={<CrownOutlined />} color="gold">
                                    Yes
                                </Tag>
                            ) : (
                                <Tag>No</Tag>
                            )}
                        </Descriptions.Item>
                        <Descriptions.Item label="Status">
                            <UserStatusDescription record={selectedUser} />
                        </Descriptions.Item>
                        <Descriptions.Item label="Auth Provider">
                            <Tag color="cyan">{selectedUser.auth_provider.toUpperCase()}</Tag>
                        </Descriptions.Item>
                        <Descriptions.Item label="Joined">
                            {new Date(selectedUser.created_at).toLocaleDateString()}
                        </Descriptions.Item>

                        <Descriptions.Item label="Demographics" span={2}>
                            <Flex gap="small" wrap="wrap">
                                {selectedUser.birth_year && <Tag color="blue">Born: {selectedUser.birth_year}</Tag>}
                                {selectedUser.gender && <Tag color="magenta">{selectedUser.gender}</Tag>}
                                {selectedUser.occupation && <Tag color="geekblue">{selectedUser.occupation}</Tag>}
                            </Flex>
                        </Descriptions.Item>

                        <Descriptions.Item label="Onboarding Stats" span={2}>
                            <Flex vertical gap="small">
                                <div>
                                    <Text strong>Financial Goal: </Text>
                                    <Tag color="purple">{selectedUser.financial_goal || 'Not Set'}</Tag>
                                </div>
                                <div>
                                    <Text strong>Risk Tolerance: </Text>
                                    <Tag color={selectedUser.risk_tolerance === 'high' ? 'red' : 'green'}>
                                        {selectedUser.risk_tolerance?.toUpperCase() || 'NOT SET'}
                                    </Tag>
                                </div>
                            </Flex>
                        </Descriptions.Item>

                        <Descriptions.Item label="Last Seen" span={2}>
                            {selectedUser.last_seen_at
                                ? new Date(selectedUser.last_seen_at).toLocaleString()
                                : 'Never'}
                        </Descriptions.Item>
                    </Descriptions>
                )}
            </Modal>
            {/* User Activity Modal */}
            <Modal
                title="User Activity Journal (Last 30 Days)"
                open={activityModalOpen}
                onCancel={() => {
                    setActivityModalOpen(false);
                    setActivityUserId(null);
                }}
                width={800}
                footer={[
                    <Button key="close" onClick={() => {
                        setActivityModalOpen(false);
                        setActivityUserId(null);
                    }}>
                        Close
                    </Button>,
                ]}
            >
                <ActivityModalContent
                    loading={activityLoading}
                    data={userActivity}
                    chartData={activityChartData}
                />
            </Modal>
        </div>
    );
}
