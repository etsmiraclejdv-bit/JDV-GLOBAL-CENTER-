'use client';
import React, { useState, useEffect } from 'react';
import { Menu, X, ChevronRight } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

export default function PublicNavbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handler);
    return () => window.removeEventListener('scroll', handler);
  }, []);

  const navLinks = [
  { label: 'Fonctionnalités', href: '#features' },
  { label: 'Tarifs', href: '#pricing' },
  { label: 'Le concepteur', href: '/a-propos-concepteur' }];


  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
      scrolled ? 'nav-glass shadow-card' : 'bg-transparent'}`
      }>

      <div className="max-w-screen-xl px-6 lg:px-10 h-16 flex items-center justify-between mx-0 mt-[51px] pl-6 rounded-t-[15px] border-0">
        <div className="flex items-center gap-3">
          <Image
            src="/assets/images/image_a5395bef-1789678648033.jpg"
            alt="JDV CRM Logo"
            width={36}
            height={36}
            className="rounded-lg object-contain flex-shrink-0"
            priority />

          <span className="font-bold text-xl tracking-tight text-foreground">
            JDV <span className="gold-gradient-text">CRM</span>
          </span>
        </div>

        <div className="hidden md:flex items-center gap-8">
          {navLinks?.map((link) =>
          <a
            key={`nav-${link?.href}`}
            href={link?.href}
            className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors duration-150">

              {link?.label}
            </a>
          )}
        </div>

        <div className="hidden md:flex items-center gap-3">
          <Link
            href="/business/login"
            className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors px-4 py-2">

            Connexion
          </Link>
          <a
            href="#register"
            className="btn-gold text-sm font-semibold px-5 py-2 rounded-xl flex items-center gap-2">

            Essai gratuit
            <ChevronRight size={14} />
          </a>
        </div>

        <button
          className="md:hidden p-2 text-muted-foreground hover:text-foreground"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label="Menu mobile">

          {mobileOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {mobileOpen &&
      <div className="md:hidden nav-glass border-t border-border animate-slide-up">
          <div className="px-6 py-4 flex flex-col gap-4">
            {navLinks?.map((link) =>
          <a
            key={`mobile-nav-${link?.href}`}
            href={link?.href}
            className="text-sm font-medium text-muted-foreground hover:text-foreground py-2"
            onClick={() => setMobileOpen(false)}>

                {link?.label}
              </a>
          )}
            <hr className="divider-gold" />
            <Link
            href="/business/login"
            className="text-sm font-medium text-muted-foreground hover:text-foreground py-2 text-center"
            onClick={() => setMobileOpen(false)}>

              Connexion
            </Link>
            <a
            href="#register"
            className="btn-gold text-sm font-semibold px-5 py-3 rounded-xl text-center"
            onClick={() => setMobileOpen(false)}>

              Démarrer l&apos;essai gratuit
            </a>
          </div>
        </div>
      }
    </nav>);

}