import React from 'react';
import classNames from 'classnames';

type ButtonProps = {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'accent' | 'ghost';
  className?: string;
};

const Button = ({children, onClick, variant = 'primary', className}: ButtonProps) => {
  const baseStyles = 'px-4 py-2 rounded-xl font-medium transition-colors';
  const variants = {
    primary: 'bg-primary text-white hover:bg-blue-900',
    accent: 'bg-accent text-white hover:bg-teal-700',
    ghost: 'bg-transparent text-primary border border-primary hover:bg-primary hover:text-white',
  };

  return (
    <button
      onClick={onClick}
      className={classNames(baseStyles, variants[variant], className)}>
      {children}
    </button>
  );
};

export default Button;
