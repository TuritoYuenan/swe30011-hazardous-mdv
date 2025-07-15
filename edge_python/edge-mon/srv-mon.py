## Copyright (C) 2025 Minh-Triet Nguyen-Ta <104993913@student.swin.edu.au>

import aiohttp
import asyncio
import logging
import os
import json

API_URL = os.getenv("API_URL", "http://localhost:8000")
DEBUG_MODE = os.getenv("DEBUG_MODE", "True").lower() == "true"

SAFE_LIMITS = {
	"lpg": 1000,
	"ch4": 1000,
	"co": 35
}

def detect_gas_leak(readings: dict, history: list) -> bool:
	"""
	Detects gas leak using threshold and sudden spike detection.
	- readings: latest reading dict
	- history: list of previous reading dicts
	Returns True if leak detected, else False.
	"""
	gases = ["lpg", "ch4", "co"]
	for gas in gases:
		values = [r[gas] for r in history] + [readings[gas]]
		last = values[-1]
		avg = sum(values) / len(values)
		stddev = (sum((v - avg) ** 2 for v in values) / len(values)) ** 0.5
		if last > SAFE_LIMITS[gas] or (last - avg > 2 * stddev):
			return True
	return False

async def main():
	"""Main monitoring daemon procedure."""
	logging.basicConfig(level=logging.INFO, format='%(asctime)s | %(levelname)s | %(message)s')

	history = []
	async with aiohttp.ClientSession() as session:
		while True:
			async with session.get(API_URL + "/readings") as response:
				response.raise_for_status()
				async for line in response.content:
					if not line: continue

					readings: dict = json.loads(line.decode('utf-8'))
					logging.info("Readings: %s", readings)

					history.append(readings)
					if len(history) > 10:
						history.pop(0)

					limit_exceeded = detect_gas_leak(readings, history)
					logging.info("Gas leak detected: %s", limit_exceeded)

					command = ("/engage" if limit_exceeded else "/disengage")
					await session.get(API_URL + "/response_system" + command)

			await asyncio.sleep(4)


if __name__ == "__main__":
	try:
		asyncio.run(main())
	except Exception as error:
		logging.error("* Error: %s", error)
	except KeyboardInterrupt:
		logging.info("* MON service manually stopped.")
