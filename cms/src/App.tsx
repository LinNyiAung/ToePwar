import React, { useState } from 'react';
import { LoginForm } from './components/auth/LoginForm';
import { SignupForm } from './components/auth/SignupForm';
import { UserTable } from './components/users/UserTable';
import { Alert } from './components/common/Alert';
import { useUsers } from './hooks/useUsers';
import { useAuth } from './hooks/useAuth';

const App: React.FC = () => {
  const [view, setView] = useState<'login' | 'signup' | 'users'>('login');
  const { logout } = useAuth();
  const { users, error, updateUserStatus, deleteUser } = useUsers();

  const handleLoginSuccess = () => {
    setView('users');
  };

  const handleSignupSuccess = () => {
    setView('login');
  };

  const handleLogout = () => {
    logout();
    setView('login');
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-4xl mx-auto">
        {error && <Alert message={error} type="error" />}

        {view === 'login' && (
          <div>
            <LoginForm onSuccess={handleLoginSuccess} />
            <button
              onClick={() => setView('signup')}
              className="mt-4 text-blue-500 hover:text-blue-600"
            >
              Need an account? Sign up
            </button>
          </div>
        )}

        {view === 'signup' && (
          <div>
            <SignupForm onSuccess={handleSignupSuccess} />
            <button
              onClick={() => setView('login')}
              className="mt-4 text-blue-500 hover:text-blue-600"
            >
              Already have an account? Log in
            </button>
          </div>
        )}

        {view === 'users' && (
          <div>
            <div className="flex justify-end mb-4">
              <button
                onClick={handleLogout}
                className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
              >
                Logout
              </button>
            </div>
            <UserTable
              users={users}
              onStatusChange={updateUserStatus}
              onDelete={deleteUser}
            />
          </div>
        )}
      </div>
    </div>
  );
};

export default App;