'use client';

import React, { memo, useMemo } from 'react';
import AppImage from './AppImage';

interface AppLogoProps {
  src?: string;
  iconName?: string;
  size?: number;
  className?: string;
  onClick?: () => void;
}

const AppLogo = memo(function AppLogo({
  src = '/assets/images/image_a5395bef-1789678648033.jpg',
  iconName = 'SparklesIcon',
  size = 64,
  className = '',
  onClick,
}: AppLogoProps) {
  const containerClassName = useMemo(() => {
    const classes = ['flex items-center'];
    if (onClick) classes.push('cursor-pointer hover:opacity-80 transition-opacity');
    if (className) classes.push(className);
    return classes.join(' ');
  }, [onClick, className]);

  return (
    <div className={containerClassName} onClick={onClick}>
      <AppImage
        src={src}
        alt="JDV CRM Logo"
        width={size}
        height={size}
        className="flex-shrink-0 object-contain rounded-lg"
        priority={true}
        unoptimized={src.endsWith('.svg')}
      />
    </div>
  );
});

export default AppLogo;
