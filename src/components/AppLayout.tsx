import React from 'react';

const AppLayout = ({children}: {children: React.ReactNode}) => {
  return (
    <div className="min-h-screen bg-secondary text-primary font-sans px-4 py-6">
      <div className="max-w-4xl mx-auto w-full">{children}</div>
    </div>
  );
};

export default AppLayout;
