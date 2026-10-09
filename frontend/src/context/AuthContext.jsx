import { createContext, useEffect, useState } from 'react'
import { getMe, login as loginRequest } from '../services/authService'

export const AuthContext = createContext(null)
const TOKEN_KEY = 'ai_websectest_token'

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const logout = () => {
    sessionStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(TOKEN_KEY)
    setUser(null)
  }

  useEffect(() => {
    const token = sessionStorage.getItem(TOKEN_KEY)
    if (!token) { setLoading(false); return undefined }
    getMe().then(setUser).catch(logout).finally(() => setLoading(false))
    window.addEventListener('auth:expired', logout)
    return () => window.removeEventListener('auth:expired', logout)
  }, [])

  const login = async (credentials) => {
    const data = await loginRequest(credentials)
    sessionStorage.setItem(TOKEN_KEY, data.access_token)
    localStorage.setItem(TOKEN_KEY, data.access_token)
    setUser(data.user)
    return data.user
  }
  return <AuthContext.Provider value={{ user, loading, login, logout, setUser }}>{children}</AuthContext.Provider>
}
