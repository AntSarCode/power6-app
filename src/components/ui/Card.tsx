import React from 'react';

type CardProps = {
  children: React.ReactNode;
  className?: string;
};

const Card = ({children, className = ''}: CardProps) => {
  return (
    <div className={`bg-white p-4 rounded-xl shadow-sm ${className}`}>
      {children}
    </div>
  );
};

export default Card;
