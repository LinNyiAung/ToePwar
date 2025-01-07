import { useState, useEffect } from 'react';
import { api } from '../services/api';
import { User } from '../types';
import { getStoredToken } from '../services/auth';

export const useUsers = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = async () => {
    const token = getStoredToken();
    if (!token) return;

    setIsLoading(true);
    setError(null);
    try {
      const data = await api.getUsers(token);
      setUsers(data);
    } catch (err) {
      setError('Failed to fetch users');
    } finally {
      setIsLoading(false);
    }
  };

  const updateUserStatus = async (userId: string, status: string) => {
    const token = getStoredToken();
    if (!token) return;

    setError(null);
    try {
      await api.updateUserStatus(userId, status, token);
      await fetchUsers();
    } catch (err) {
      setError('Failed to update user status');
    }
  };

  const deleteUser = async (userId: string) => {
    const token = getStoredToken();
    if (!token) return;

    setError(null);
    try {
      await api.deleteUser(userId, token);
      await fetchUsers();
    } catch (err) {
      setError('Failed to delete user');
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return { users, isLoading, error, fetchUsers, updateUserStatus, deleteUser };
};