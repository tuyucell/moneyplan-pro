import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, theme, App as AntdApp } from 'antd';
import { useAuthStore } from './store/authStore';
import { useThemeStore } from './store/themeStore';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard.tsx';
import Users from './pages/Users';
import Analytics from './pages/Analytics';
import LiveMonitor from './pages/LiveMonitor';
import SystemTasks from './pages/SystemTasks';
import AppSettings from './pages/AppSettings';
import AdsManager from './pages/AdsManager';
import NotificationsManager from './pages/NotificationsManager';
import FeatureFlags from './pages/FeatureFlags';
import PricingManager from './pages/PricingManager';
import AnnouncementsManager from './pages/AnnouncementsManager';
import LimitsManager from './pages/LimitsManager';
import UIManager from './pages/UIManager';
import AdminGuide from './pages/AdminGuide';
import PriceAlertsManager from './pages/PriceAlertsManager';
import AuditLogs from './pages/AuditLogs';
import DeletionRequests from './pages/DeletionRequests';
import Layout from './components/Layout';
import './App.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});

function App() {
  const { isAuthenticated, isLoading, checkAuth } = useAuthStore();
  const { isDark } = useThemeStore();

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  if (isLoading) {
    return (
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh'
      }}>
        Loading...
      </div>
    );
  }

  return (
    <ConfigProvider
      theme={{
        algorithm: isDark ? theme.darkAlgorithm : theme.defaultAlgorithm,
        token: {
          colorPrimary: '#1890ff',
          borderRadius: 8,
        },
      }}
    >
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <AntdApp>
            <Routes>
              <Route
                path="/login"
                element={isAuthenticated ? <Navigate to="/" /> : <Login />}
              />
              <Route
                path="/*"
                element={
                  isAuthenticated ? (
                    <Layout>
                      <Routes>
                        <Route path="/" element={<Dashboard />} />
                        <Route path="/users" element={<Users />} />
                        <Route path="/analytics" element={<Analytics />} />
                        <Route path="/live" element={<LiveMonitor />} />
                        <Route path="/system/tasks" element={<SystemTasks />} />
                        <Route path="/system/settings" element={<AppSettings />} />
                        <Route path="/system/ads" element={<AdsManager />} />
                        <Route path="/system/notifications" element={<NotificationsManager />} />
                        <Route path="/system/features" element={<FeatureFlags />} />
                        <Route path="/system/pricing" element={<PricingManager />} />
                        <Route path="/system/announcements" element={<AnnouncementsManager />} />
                        <Route path="/system/limits" element={<LimitsManager />} />
                        <Route path="/system/ui" element={<UIManager />} />
                        <Route path="/system/alerts" element={<PriceAlertsManager />} />
                        <Route path="/system/audit-logs" element={<AuditLogs />} />
                        <Route path="/system/kvkk" element={<DeletionRequests />} />
                        <Route path="/guide" element={<AdminGuide />} />
                        <Route path="*" element={<Navigate to="/" />} />
                      </Routes>
                    </Layout>
                  ) : (
                    <Navigate to="/login" />
                  )
                }
              />
            </Routes>
          </AntdApp>
        </BrowserRouter>
      </QueryClientProvider>
    </ConfigProvider>
  );
}

export default App;
