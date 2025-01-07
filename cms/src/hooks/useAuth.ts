import { useState } from 'react';
import { api } from '../services/api';
import { LoginCredentials, SignupData } from '../types';
import { setStoredToken, removeStoredToken } from '../services/auth';

export const useAuth = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const login = async (credentials: LoginCredentials) => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await api.login(credentials);
      setStoredToken(response.access_token);
      return true;
    } catch (err) {
      setError('Login failed. Please check your credentials.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const signup = async (data: SignupData) => {
    setIsLoading(true);
    setError(null);
    try {
      await api.signup(data);
      return true;
    } catch (err) {
      setError('Signup failed. Please check your information.');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    removeStoredToken();
  };

  return { login, signup, logout, isLoading, error };
};