import React from 'react';
import { AlertCircle, CheckCircle } from 'lucide-react';

interface AlertProps {
  message: string;
  type: 'success' | 'error';
  onClose?: () => void;
}

export const Alert: React.FC<AlertProps> = ({ message, type, onClose }) => {
  const bgColor = type === 'success' ? 'bg-green-100' : 'bg-red-100';
  const textColor = type === 'success' ? 'text-green-800' : 'text-red-800';
  const Icon = type === 'success' ? CheckCircle : AlertCircle;

  return (
    <div className={`${bgColor} ${textColor} p-4 rounded-lg flex items-center justify-between mb-4`}>
      <div className="flex items-center">
        <Icon className="w-5 h-5 mr-2" />
        <span>{message}</span>
      </div>
      {onClose && (
        <button onClick={onClose} className="ml-auto">
          ×
        </button>
      )}
    </div>
  );
};