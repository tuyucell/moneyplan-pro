import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { User } from '@supabase/supabase-js';

interface AuthState {
    user: User | null;
    isLoading: boolean;
    isAuthenticated: boolean;
    login: (email: string, password: string) => Promise<void>;
    logout: () => Promise<void>;
    checkAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
    user: null,
    isLoading: true,
    isAuthenticated: false,

    login: async (email: string, password: string) => {
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });

        if (error) throw error;

        set({ user: data.user, isAuthenticated: true });
    },

    logout: async () => {
        await supabase.auth.signOut();
        set({ user: null, isAuthenticated: false });
    },

    checkAuth: async () => {
        try {
            const { data } = await supabase.auth.getSession();
            set({
                user: data.session?.user || null,
                isAuthenticated: !!data.session,
                isLoading: false,
            });
        } catch (error) {
            console.error('Auth check failed:', error);
            set({ user: null, isAuthenticated: false, isLoading: false });
        }
    },
}));
