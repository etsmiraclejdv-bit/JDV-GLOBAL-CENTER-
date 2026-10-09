import React from 'react';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  padding?: 'none' | 'sm' | 'md' | 'lg';
  hover?: boolean;
}

const paddingMap = {
  none: '',
  sm: 'p-4',
  md: 'p-5',
  lg: 'p-6',
};

export default function Card({ children, className = '', padding = 'md', hover = false }: CardProps) {
  return (
    <div
      className={`bg-[#0F2347] border border-[rgba(212,175,55,0.15)] rounded-2xl ${paddingMap[padding]} ${hover ? 'feature-card-hover cursor-pointer' : ''} ${className}`}
    >
      {children}
    </div>
  );
}
