import os


def listDirectory(folderpath, match_folder=''):

    folderpath = os.path.expanduser(folderpath)
    list_folders = [dI for dI in os.listdir(
        folderpath) if os.path.isdir(os.path.join(folderpath, dI))]

    folder_name = [i for i in list_folders if match_folder in i]

    sort_folders = sorted(folder_name)

    return sort_folders


def writeSample(basePath, nChans, duration):

    b1 = np.memmap(fileName, dtype='int16', mode='r', shape=(1, 30000*134*20))
    ThetaExtract = b1[reqChan::nChans]
    data = b1
    file = open(basePath+subname+'_Example.dat', "wb")

    file.write(data)
    file.close()
