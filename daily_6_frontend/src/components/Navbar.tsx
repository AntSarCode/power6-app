import { Link, useLocation } from 'react-router-dom';

const navStyle: React.CSSProperties = {
    display: 'flex',
    gap: '1rem',
    padding: '1rem 2rem',
    background: '#0f172a',
    color: 'white',
    fontWeight: 500,
};

const activeStyle: React.CSSProperties = {
    textDecoration: 'underline',
    color: '#38bdf8',
};

export default function Navbar() {
    const location = useLocation();

    return (
        <nav style={navStyle}>
            <Link to="/" style={location.pathname === '/' ? activeStyle : undefined}>
                Home
            </Link>
            <Link to="/dashboard" style={location.pathname === '/dashboard' ? activeStyle : undefined}>
                Dashboard
            </Link>
            <Link to="/input" style={location.pathname === '/input' ? activeStyle : undefined}>
                Task Input
            </Link>
            <Link to="/review" style={location.pathname === '/review' ? activeStyle : undefined}>
                Task Review
            </Link>
            <Link to="/streak" style={location.pathname === '/streak' ? activeStyle : undefined}>
                Streak Tracker
            </Link>
            <Link to="/subscribe" style={location.pathname === '/subscribe' ? activeStyle : undefined}>
                Subscription
            </Link>
            <Link to="/stats" style={location.pathname === '/stats' ? activeStyle : undefined}>
                Stats
            </Link>
        </nav>
    );
}
