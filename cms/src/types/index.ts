export interface User {
    id: string;
    username: string;
    email: string;
    status: 'active' | 'suspended' | 'banned';
    created_at: string;
  }
  
  export interface LoginCredentials {
    email: string;
    password: string;
  }
  
  export interface SignupData extends LoginCredentials {
    username: string;
    super_admin_key: string;
  }
  
  export interface AuthResponse {
    access_token: string;
    token_type: string;
  }
  
  export interface AlertProps {
    message: string;
    type: 'success' | 'error';
  }