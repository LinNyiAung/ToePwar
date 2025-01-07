import React from 'react';
import { User } from '../../types';
import { Users } from 'lucide-react';

interface UserTableProps {
  users: User[];
  onStatusChange: (userId: string, status: string) => void;
  onDelete: (userId: string) => void;
}

export const UserTable: React.FC<UserTableProps> = ({ users, onStatusChange, onDelete }) => {
  return (
    <div className="bg-white p-6 rounded-lg shadow-md">
      <div className="flex items-center mb-6">
        <Users className="w-6 h-6 mr-2" />
        <h2 className="text-2xl font-bold">User Management</h2>
      </div>
      
      <div className="overflow-x-auto">
        <table className="min-w-full table-auto">
          <thead>
            <tr className="bg-gray-100">
              <th className="px-4 py-2 text-left">Username</th>
              <th className="px-4 py-2 text-left">Email</th>
              <th className="px-4 py-2 text-left">Status</th>
              <th className="px-4 py-2 text-left">Created At</th>
              <th className="px-4 py-2 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-b">
                <td className="px-4 py-2">{user.username}</td>
                <td className="px-4 py-2">{user.email}</td>
                <td className="px-4 py-2">
                  <select
                    value={user.status}
                    onChange={(e) => onStatusChange(user.id, e.target.value)}
                    className="p-1 border rounded"
                  >
                    <option value="active">Active</option>
                    <option value="suspended">Suspended</option>
                    <option value="banned">Banned</option>
                  </select>
                </td>
                <td className="px-4 py-2">{user.created_at}</td>
                <td className="px-4 py-2">
                  <button
                    onClick={() => {
                      if (window.confirm('Are you sure you want to delete this user?')) {
                        onDelete(user.id);
                      }
                    }}
                    className="bg-red-500 text-white px-3 py-1 rounded hover:bg-red-600"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};