import { User, LoginCredentials, SignupData, AuthResponse } from '../types';

const BASE_URL = '/admin';

export const api = {
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await fetch(`${BASE_URL}/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
    });
    
    if (!response.ok) throw new Error('Login failed');
    return response.json();
  },

  signup: async (data: SignupData): Promise<void> => {
    const response = await fetch(`${BASE_URL}/signup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) throw new Error('Signup failed');
  },

  getUsers: async (token: string): Promise<User[]> => {
    const response = await fetch(`${BASE_URL}/users`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });
    
    if (!response.ok) throw new Error('Failed to fetch users');
    return response.json();
  },

  updateUserStatus: async (userId: string, status: string, token: string): Promise<void> => {
    const response = await fetch(`${BASE_URL}/users/${userId}/status`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status }),
    });
    
    if (!response.ok) throw new Error('Failed to update user status');
  },

  deleteUser: async (userId: string, token: string): Promise<void> => {
    const response = await fetch(`${BASE_URL}/users/${userId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });
    
    if (!response.ok) throw new Error('Failed to delete user');
  },
};