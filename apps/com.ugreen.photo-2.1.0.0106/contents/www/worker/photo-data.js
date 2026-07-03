const limitHeightMap = {
  36: 60,
  60: 120,
  120: 160,
  160: 220,
  220: 320,
  320: 320,
};

let cachedDate = new Date();
let cachedTimestamp = null;

const getCachedDate = timestamp => {
  if (cachedTimestamp !== timestamp) {
    cachedDate.setTime(timestamp);
    cachedTimestamp = timestamp;
  }
  return cachedDate;
};

const formatUTCDate = timestamp => {
  const date = getCachedDate(timestamp);
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
};

const isSameDay = (timestamp1, timestamp2) => {
  const date1 = getCachedDate(timestamp1);
  const year1 = date1.getUTCFullYear();
  const month1 = date1.getUTCMonth();
  const day1 = date1.getUTCDate();

  const date2 = getCachedDate(timestamp2);
  const year2 = date2.getUTCFullYear();
  const month2 = date2.getUTCMonth();
  const day2 = date2.getUTCDate();

  return year1 === year2 && month1 === month2 && day1 === day2;
};

const getDayStartTimestamp = timestamp => {
  const date = getCachedDate(timestamp);
  const dayStart = new Date(date);
  dayStart.setUTCHours(0, 0, 0, 0);
  return dayStart.getTime();
};

const updateYearMonthMap = (item, curHeight, yearMonthMap, yearMonthList) => {
  if (!item.create_time_utc || item.create_time_utc <= 0) {
    return;
  }

  const monthKey = formatUTCDate(item.create_time_utc * 1000);
  const lastYearMonth = yearMonthList[yearMonthList.length - 1];

  if (monthKey !== lastYearMonth) {
    yearMonthList.push(monthKey);

    if (!yearMonthMap[monthKey]) {
      yearMonthMap[monthKey] = {
        startPosition: curHeight,
        endPosition: 0,
        height: 0,
      };
    }

    if (lastYearMonth && yearMonthMap[lastYearMonth]) {
      yearMonthMap[lastYearMonth].endPosition = curHeight;
      yearMonthMap[lastYearMonth].height = curHeight - yearMonthMap[lastYearMonth].startPosition;
    }
  }
};

const initYearMonthMap = (item, yearMonthMap, yearMonthList) => {
  if (!item.create_time_utc || item.create_time_utc <= 0) {
    return null;
  }

  const key = formatUTCDate(item.create_time_utc * 1000);
  yearMonthMap[key] = {
    startPosition: 0,
    endPosition: 0,
    height: 0,
  };
  yearMonthList.push(key);
  return key;
};

/**
 * 计算 Aspect 模式下的项目尺寸与宽高比
 */
const getItemPosition = (pictureId, width, height, orientation, rotation, size, clientWidth) => {
  let scaleHeight = height;
  let scaleWidth = width;
  const rot = Number(rotation || 0);
  const ori = Number(orientation || 0);
  if (rot === 90 || rot === 270 || ori === 90 || ori === 270) {
    scaleHeight = width;
    scaleWidth = height;
  }
  if (!pictureId || scaleHeight <= 0 || scaleWidth <= 0) {
    return { width: size, height: size, aspectRatio: 1 };
  }

  const aspectRatio = scaleWidth / scaleHeight;
  const scale = size / scaleHeight;
  const fileWidth = scaleWidth * scale;

  return {
    width: fileWidth < clientWidth ? fileWidth : clientWidth,
    height: size,
    aspectRatio,
  };
};

/**
 * 按等高分配合比例分配宽度，可选 fillRow 填满整行并做缩放
 */
const updateRowItem = ({ row, rowWidth, clientWidth, baseHeight, gap, fillRow = true, groupByDay = false }) => {
  const limitHeight = limitHeightMap[baseHeight];
  const targetWidth = fillRow ? clientWidth : rowWidth;
  const allocationWidth = (targetWidth - rowWidth) / row.length;

  const validRow = [];
  let totalAdjustedHeight = 0;

  for (let i = 0; i < row.length; i++) {
    const item = row[i];
    if (!item) continue;
    const aspectRatio = item.aspectRatio || 1;
    if (aspectRatio > 0) {
      totalAdjustedHeight += (item.scaleWidth + allocationWidth) / aspectRatio;
      validRow.push(item);
    }
  }

  if (validRow.length === 0) return;

  let unifiedHeight = totalAdjustedHeight / validRow.length;
  if (baseHeight && unifiedHeight < baseHeight) unifiedHeight = baseHeight;
  if (limitHeight && unifiedHeight > limitHeight) unifiedHeight = limitHeight;

  let totalRequiredWidth = 0;
  let left = 0;
  for (const item of validRow) {
    const w = unifiedHeight * (item.aspectRatio || 1);
    item.scaleWidth = w;
    item.scaleHeight = unifiedHeight;
    item.left = left;
    left += w + gap;
    totalRequiredWidth += w;
  }

  const totalGapWidth = (validRow.length - 1) * gap;
  const scaleFactor = totalRequiredWidth > 0 ? (targetWidth - totalGapWidth) / totalRequiredWidth : 1;
  if (scaleFactor !== 1) {
    left = 0;
    for (const item of validRow) {
      item.scaleWidth *= scaleFactor;
      item.scaleHeight *= scaleFactor;
      item.left = left;
      left += item.scaleWidth + gap;
    }
  }
};

/**
 * Aspect 布局计算（仅处理非方形视图）
 * 此 Worker 仅在 isTimeLine && !isSquare 时被调用
 */
const computeAspectLayout = ({ photoData, clientWidth, size, gap, groupByDay = false }) => {
  if (!Array.isArray(photoData)) {
    postMessage({ list: [], yearMonthMap: {}, rowStartIndices: [] });
    return;
  }

  let curHeight = 0;
  let curWidth = 0;
  let curRow = [];
  let lastTimestamp = null;
  const yearMonthMap = {};
  const yearMonthList = [];
  const rowStartIndices = [];
  const dateDividerHeight = 40;
  const dateGroupGap = 20;

  for (let i = 0; i < photoData.length; i++) {
    const item = photoData[i];

    const { width, height, aspectRatio } = getItemPosition(
      item.picture_id,
      item.width,
      item.height,
      item.orientation,
      item.rotation,
      size,
      clientWidth
    );

    item.scaleHeight = height;
    item.scaleWidth = width;
    item.aspectRatio = aspectRatio;

    const currentTimestamp = item.create_time_utc * 1000;
    const isDateChanged = groupByDay && lastTimestamp && !isSameDay(currentTimestamp, lastTimestamp);

    if (i === 0) {
      initYearMonthMap(item, yearMonthMap, yearMonthList);
      rowStartIndices.push(0);

      if (groupByDay) {
        curHeight += dateDividerHeight;
        lastTimestamp = currentTimestamp;
        item.isDateStart = true;
        item.dateTimestamp = getDayStartTimestamp(currentTimestamp);
      }
      item.top = curHeight;
    } else {
      item.top = curHeight;
    }

    const shouldForceNewRow = isDateChanged && curRow.length > 0;

    if (!shouldForceNewRow && item.scaleWidth + curWidth + gap < clientWidth) {
      curRow.push(item);
      curWidth += item.scaleWidth;

      if (i === photoData.length - 1) {
        updateRowItem({ row: curRow, rowWidth: curWidth, clientWidth, baseHeight: size, gap, fillRow: false });
      }
    } else {
      if (curRow.length > 0) {
        updateRowItem({ row: curRow, rowWidth: curWidth, clientWidth, baseHeight: size, gap, fillRow: true });
        const perItem = photoData[i - 1];
        curHeight += perItem.scaleHeight + gap;
      }

      if (isDateChanged) {
        curHeight += dateDividerHeight + (groupByDay ? dateGroupGap : 0);
      }

      item.top = curHeight;
      curRow = [item];
      curWidth = item.scaleWidth;
      rowStartIndices.push(i);

      if (groupByDay) {
        if (isDateChanged) {
          item.isDateStart = true;
          item.dateTimestamp = getDayStartTimestamp(currentTimestamp);
        }
        lastTimestamp = currentTimestamp;
      }

      updateYearMonthMap(item, curHeight, yearMonthMap, yearMonthList);

      if (i === photoData.length - 1) {
        updateRowItem({ row: curRow, rowWidth: curWidth, clientWidth, baseHeight: size, gap, fillRow: false });
      }
    }
  }

  postMessage({ list: photoData, yearMonthMap, rowStartIndices });
};

addEventListener('message', function (event) {
  try {
    const data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
    computeAspectLayout(data);
  } catch (error) {
    postMessage({ list: [], yearMonthMap: {}, rowStartIndices: [] });
  }
});
