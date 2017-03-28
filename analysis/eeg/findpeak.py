
# a 'peak' is the maximum value from a region of values that stands
# out above the other values

# TODO: do I need the peak to be a certain width?
@jit(nopython=True)
def findpeaks__(xs,t,peak_indices):
  peakstart = -1
  peak_count = 0
  for i in range(len(xs)):
    if peakstart < 0:
      if  xs[i] > t:
        if peak_count < len(peak_indices):
          peakstart = i
          peak_count += 1
          peak_indices[peak_count-1] = i
    else:
      if xs[i] > t:
        if xs[peak_indices[peak_count-1]] < xs[i]:
          peak_indices[peak_count-1] = i
      else:
        peakstart = -1

def findpeaks(xs,peaks,relt=0.95,minwidth=35e-6):
  thresh = relt*max(minwidth,np.percentile(xs,95) - np.min(xs)) + np.min(xs)
  peak_indices[:] = -1
  findpeaks__(xs,thresh,peak_indices)
  indices = np.where(peak_indices >= 0)
  if len(indices) == len(peak_indices):
    warn("Max peaks reached. You may want to increase the maximum"+
         " number of peaks per epoch.")

  result = np.copy(peak_indices[indices])
  peak_indices[indices] = -1
  return result
