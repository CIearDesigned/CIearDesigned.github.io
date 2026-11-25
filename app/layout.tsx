import type { Metadata } from 'next';
import './globals.css';
import { Navbar } from '@/components/navbar';
export const metadata: Metadata = { title: 'Devur — Game projects, ready to play', description: 'Discover, buy, and sell complete game projects and creator assets.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body><Navbar />{children}<footer className="border-t border-[#202530] mt-24"><div className="container py-8 flex flex-col sm:flex-row gap-3 justify-between text-sm text-[#858c9b]"><span>© 2026 Devur. Built for the people who build games.</span><span>Trade fairly. Transfer safely. Never sell accounts.</span></div></footer></body></html>; }
