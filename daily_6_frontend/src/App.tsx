import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Home from './pages/Home';
import TaskInput from './pages/TaskInput';
import TaskReview from './pages/TaskReview';
import NotFound from './pages/NotFound';
import StreakTracker from './pages/StreakTracker';
import SubscriptionScreen from './pages/SubscriptionScreen';
import StatsDashboard from './pages/StatsDashboard';

export default function App() {
    return (
        <BrowserRouter>
            <Navbar />
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/input" element={<TaskInput />} />
                <Route path="/review" element={<TaskReview />} />
                <Route path="*" element={<NotFound />} />
                <Route path="/streak" element={<StreakTracker />} />
                <Route path="/subscribe" element={<SubscriptionScreen />} />
                <Route path="/stats" element={<StatsDashboard />} />
            </Routes>
        </BrowserRouter>
    );
}
