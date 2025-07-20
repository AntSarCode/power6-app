import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import {useEffect, useState} from 'react';

export default function Dashboard() {
  const [taskComplete,setTaskComplete] = useState(false);

  useEffect(() => {
    const timeout = setTimeout(() => setTaskComplete(true),500);
    return () => clearTimeout(timeout);
  },[]);

  return (
    <div>
      <Card>
        <h2>Streak Progress</h2>
        <p>You're on a 5-day streak! Keep it going!</p>
      </Card>
      <Card>
        <h2>Task Completion</h2>
        <p>4 of 6 tasks completed today.</p>
      </Card>
      <Card>
        <div>
          <h2>Upgrade for Stats</h2>
          <p>Unlock full analytics and trends over time.</p>
        </div>
        <Button variant="accent">Go Premium</Button>
      </Card>
    </div>
  );
}
