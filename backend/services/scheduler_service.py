import asyncio
import logging
from datetime import datetime, timedelta
from services.market_service import market_provider

logger = logging.getLogger(__name__)

class SchedulerService:
    def __init__(self):
        self._task = None
        self._is_running = False

    def start(self):
        if self._is_running:
            return
        self._is_running = True
        self._task = asyncio.create_task(self._scheduler_loop())
        logger.info("Scheduler Service started (Daily Mirror Sync).")

    async def _scheduler_loop(self):
        while self._is_running:
            try:
                # 1. Sync Calendar Actuals
                logger.info("Running scheduled task: sync_calendar_to_db")
                market_provider.sync_calendar_to_db()
                
                # 2. Calculate time to next 00:00
                now = datetime.now()
                tomorrow = now + timedelta(days=1)
                next_midnight = datetime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 1)
                wait_seconds = (next_midnight - now).total_seconds()
                
                logger.info(f"Next sync scheduled for {next_midnight.isoformat()} (in {wait_seconds:.0f} seconds).")
                await asyncio.sleep(wait_seconds)
                
            except Exception as e:
                logger.error(f"Error in Scheduler Loop: {e}")
                await asyncio.sleep(300) # Wait 5 mins on error

    def stop(self):
        self._is_running = False
        if self._task:
            self._task.cancel()
        logger.info("Scheduler Service stopped.")

scheduler_service = SchedulerService()
