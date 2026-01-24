import type { ReactNode } from 'react';
import { useState } from 'react';
import { Layout as AntLayout, Menu, Avatar, Dropdown, Typography, Switch, Space, Flex } from 'antd';
import type { MenuProps } from 'antd';
import {
    DashboardOutlined,
    UserOutlined,
    LogoutOutlined,
    BarChartOutlined,
    BulbOutlined,
    BulbFilled,
    ThunderboltOutlined,
    ToolOutlined,
    SettingOutlined,
    SyncOutlined,
    NotificationOutlined,
    BellOutlined,
    DollarOutlined,
    BgColorsOutlined,
    BookOutlined,
    DeleteOutlined,
} from '@ant-design/icons';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { useThemeStore } from '../store/themeStore';

const { Header, Sider, Content } = AntLayout;
const { Text } = Typography;

interface LayoutProps {
    readonly children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
    const [collapsed, setCollapsed] = useState(false);
    const navigate = useNavigate();
    const location = useLocation();
    const { user, logout } = useAuthStore();
    const { isDark, toggleTheme } = useThemeStore();

    const menuItems: MenuProps['items'] = [
        {
            key: '/',
            icon: <DashboardOutlined />,
            label: 'Dashboard',
            onClick: () => { navigate('/'); },
        },
        {
            key: '/users',
            icon: <UserOutlined />,
            label: 'Users',
            onClick: () => { navigate('/users'); },
        },
        {
            key: '/analytics',
            icon: <BarChartOutlined />,
            label: 'Analytics',
            onClick: () => { navigate('/analytics'); },
        },
        {
            key: '/live',
            icon: <ThunderboltOutlined />,
            label: 'Live Monitor',
            onClick: () => { navigate('/live'); },
        },
        {
            key: 'system',
            icon: <ToolOutlined />,
            label: 'System',
            children: [
                {
                    key: '/system/tasks',
                    icon: <SyncOutlined />,
                    label: 'Tasks & Scripts',
                    onClick: () => { navigate('/system/tasks'); },
                },
                {
                    key: '/system/settings',
                    icon: <SettingOutlined />,
                    label: 'App Settings',
                    onClick: () => { navigate('/system/settings'); },
                },
                {
                    key: '/system/ads',
                    icon: <NotificationOutlined />,
                    label: 'Ads Manager',
                    onClick: () => { navigate('/system/ads'); },
                },
                {
                    key: '/system/notifications',
                    icon: <BellOutlined />,
                    label: 'Push Notifications',
                    onClick: () => { navigate('/system/notifications'); },
                },
                {
                    key: '/system/features',
                    icon: <BulbOutlined />,
                    label: 'Feature Flags',
                    onClick: () => { navigate('/system/features'); },
                },
                {
                    key: '/system/pricing',
                    icon: <DollarOutlined />,
                    label: 'Pricing & Promos',
                    onClick: () => { navigate('/system/pricing'); },
                },
                {
                    key: '/system/announcements',
                    icon: <NotificationOutlined />,
                    label: 'System Announcements',
                    onClick: () => { navigate('/system/announcements'); },
                },
                {
                    key: '/system/limits',
                    icon: <DashboardOutlined />,
                    label: 'User Limits',
                    onClick: () => { navigate('/system/limits'); },
                },
                {
                    key: '/system/alerts',
                    icon: <BellOutlined />,
                    label: 'Price Alerts',
                    onClick: () => { navigate('/system/alerts'); },
                },
                {
                    key: '/system/ui',
                    icon: <BgColorsOutlined />,
                    label: 'System Branding',
                    onClick: () => { navigate('/system/ui'); },
                },
                {
                    key: '/system/audit-logs',
                    icon: <BookOutlined />,
                    label: 'Audit Logs',
                    onClick: () => { navigate('/system/audit-logs'); },
                },
                {
                    key: '/system/kvkk',
                    icon: <DeleteOutlined />,
                    label: 'KVKK Silme Talepleri',
                    onClick: () => { navigate('/system/kvkk'); },
                },
            ],
        },
        {
            key: '/guide',
            icon: <BookOutlined />,
            label: 'User Guide',
            onClick: () => { navigate('/guide'); },
        },
    ];

    const userMenuItems: MenuProps['items'] = [
        {
            key: 'logout',
            icon: <LogoutOutlined />,
            label: 'Logout',
            onClick: () => { void logout(); },
        },
    ];

    return (
        <AntLayout style={{ minHeight: '100vh' }}>
            <Sider
                collapsible
                collapsed={collapsed}
                onCollapse={setCollapsed}
                theme={isDark ? 'dark' : 'light'}
                style={{
                    boxShadow: '2px 0 8px rgba(0,0,0,0.08)',
                    borderRight: isDark ? 'none' : '1px solid #f0f0f0',
                }}
            >
                <div
                    style={{
                        height: '64px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: collapsed ? '20px' : '24px',
                        fontWeight: 'bold',
                        color: isDark ? '#fff' : '#1890ff',
                        transition: 'all 0.2s',
                        borderBottom: isDark ? '1px solid #303030' : '1px solid #f0f0f0',
                    }}
                >
                    {collapsed ? '💰' : '💰 MoneyPlan Pro'}
                </div>
                <Menu
                    theme={isDark ? 'dark' : 'light'}
                    mode="inline"
                    selectedKeys={[location.pathname]}
                    items={menuItems}
                />
            </Sider>

            <AntLayout>
                <Header
                    style={{
                        padding: '0 24px',
                        background: isDark ? '#001529' : '#fff',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
                        borderBottom: isDark ? 'none' : '1px solid #f0f0f0',
                    }}
                >
                    <Text style={{ color: isDark ? '#fff' : '#333', fontSize: '18px', fontWeight: 500 }}>
                        Admin Panel
                    </Text>

                    <Flex gap="middle" align="center">
                        <Space>
                            {isDark ? <BulbFilled style={{ color: '#faad14' }} /> : <BulbOutlined />}
                            <Switch
                                checked={isDark}
                                onChange={toggleTheme}
                                checkedChildren="Dark"
                                unCheckedChildren="Light"
                            />
                        </Space>

                        <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
                            <div style={{ display: 'flex', alignItems: 'center', cursor: 'pointer', gap: '8px' }}>
                                <Text style={{ color: isDark ? '#fff' : '#333' }}>{user?.email}</Text>
                                <Avatar icon={<UserOutlined />} />
                            </div>
                        </Dropdown>
                    </Flex>
                </Header>

                <Content style={{ margin: '24px', minHeight: 'calc(100vh - 112px)' }}>
                    {children}
                </Content>
            </AntLayout>
        </AntLayout>
    );
}
