import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Table, Card, Typography, Tag, Input, Space, Button, Modal, Flex } from 'antd';
import { SearchOutlined, ReloadOutlined, EyeOutlined } from '@ant-design/icons';
import { supabase } from '../lib/supabase';
import type { ColumnsType } from 'antd/es/table';

const { Title, Text } = Typography;

interface AuditLog {
    id: number;
    user_id: string;
    action: string;
    details: any;
    ip_address: string;
    created_at: string;
    // Joined fields
    users?: {
        email: string;
        display_name: string;
    };
}

export default function AuditLogs() {
    const [searchText, setSearchText] = useState('');
    const [viewDetails, setViewDetails] = useState<any>(null);

    const { data: logs, isLoading, refetch } = useQuery({
        queryKey: ['audit-logs'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('audit_logs')
                .select(`
                    *,
                    users:user_id (email, display_name)
                `)
                .order('created_at', { ascending: false })
                .limit(100);

            if (error) {
                console.error('Error fetching audit logs:', error);
                return [];
            }
            return data as AuditLog[];
        },
    });

    const getActionColor = (action: string) => {
        if (action.includes('LOGIN')) return 'green';
        if (action.includes('DELETE')) return 'red';
        if (action.includes('UPDATE')) return 'blue';
        if (action.includes('CREATE')) return 'cyan';
        return 'default';
    };

    const columns: ColumnsType<AuditLog> = [
        {
            title: 'Time',
            dataIndex: 'created_at',
            key: 'created_at',
            width: 180,
            render: (date: string) => new Date(date).toLocaleString('tr-TR'),
            sorter: (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
        },
        {
            title: 'User',
            key: 'user',
            render: (record: AuditLog) => (
                <Flex vertical gap={0}>
                    <Text strong>{record.users?.email || 'Unknown'}</Text>
                    <Text type="secondary" style={{ fontSize: '12px' }}>{record.user_id}</Text>
                </Flex>
            ),
        },
        {
            title: 'Action',
            dataIndex: 'action',
            key: 'action',
            render: (action: string) => (
                <Tag color={getActionColor(action)}>{action}</Tag>
            ),
            filters: [
                { text: 'Login', value: 'LOGIN' },
                { text: 'Update', value: 'UPDATE' },
                { text: 'Create', value: 'CREATE' },
                { text: 'Delete', value: 'DELETE' },
            ],
            onFilter: (value, record) => record.action.includes(value as string),
        },
        {
            title: 'IP Address',
            dataIndex: 'ip_address',
            key: 'ip_address',
        },
        {
            title: 'Details',
            key: 'details',
            render: (record: AuditLog) => (
                <Button
                    type="link"
                    icon={<EyeOutlined />}
                    onClick={() => setViewDetails(record.details)}
                >
                    View
                </Button>
            ),
        },
    ];

    const filteredLogs = logs?.filter(log =>
        log.action.toLowerCase().includes(searchText.toLowerCase()) ||
        log.users?.email.toLowerCase().includes(searchText.toLowerCase()) ||
        log.user_id.includes(searchText)
    );

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <Title level={2} style={{ margin: 0 }}>🛡️ Audit Logs</Title>
                <Space>
                    <Input
                        placeholder="Search logs..."
                        prefix={<SearchOutlined />}
                        onChange={e => setSearchText(e.target.value)}
                        style={{ width: 250 }}
                    />
                    <Button icon={<ReloadOutlined />} onClick={() => refetch()}>Refresh</Button>
                </Space>
            </div>

            <Card>
                <Table
                    columns={columns}
                    dataSource={filteredLogs}
                    loading={isLoading}
                    rowKey="id"
                    pagination={{ pageSize: 20, showSizeChanger: true }}
                />
            </Card>

            <Modal
                title="Log Details"
                open={!!viewDetails}
                onCancel={() => setViewDetails(null)}
                footer={null}
            >
                <pre style={{ background: '#f5f5f5', padding: '12px', borderRadius: '4px', overflow: 'auto' }}>
                    {JSON.stringify(viewDetails, null, 2)}
                </pre>
            </Modal>
        </div>
    );
}
