import { useState } from 'react'
import Navbar from './Navbar'
import Sidebar from './Sidebar'
export default function AppShell({ children }) { const [open, setOpen] = useState(false); return <div className={`app-shell ${open ? 'menu-open' : ''}`}><Sidebar onNavigate={() => setOpen(false)} /><div className="shell-main"><Navbar toggleMenu={() => setOpen(!open)} /><main>{children}</main></div></div> }
