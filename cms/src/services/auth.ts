export const getStoredToken = () => localStorage.getItem('adminToken');
export const setStoredToken = (token: string) => localStorage.setItem('adminToken', token);
export const removeStoredToken = () => localStorage.removeItem('adminToken');